--[[
	TODO:
	* Find player entity
	* Find all entities around player with lights
	* Get light data and pass to shader
		- X,Y,RGB,Size
	* Create bump map for each light
	* Wish you could pass different stuff than vec4 to shaders
]]

dofile("mods/da_bumpmap/lib/script_utilities.lua")

script.append([[
uniform vec4 bump_settings1;
uniform vec4 bump_settings2;

uniform vec4 light1;

// -----------------------------------------------------------------------------------------------
// rgb2hsl
// https://www.shadertoy.com/view/XljGzV

vec4 rgb2hsl(vec4 c) {
	float h = 0.0;
	float s = 0.0;
	float l = 0.0;
	float r = c.r;
	float g = c.g;
	float b = c.b;
	float cMin = min(r, min(g, b));
	float cMax = max(r, max(g, b));
	l = (cMax + cMin) / 2.0;
	if (cMax > cMin) {
		float cDelta = cMax - cMin;
		s = l < .0 ? cDelta / (cMax + cMin) : cDelta / (2.0 - (cMax + cMin));
		if (r == cMax) {
			h = (g - b) / cDelta;
		}
		else if (g == cMax) {
			h = 2.0 + (b - r) / cDelta;
		}
		else {
			h = 4.0 + (r - g) / cDelta;
		}
		if (h < 0.0) {
			h += 6.0;
		}
		h = h / 6.0;
	}
	return vec4(h, s, l, c.a);
}
vec3 rgb2hsl(vec3 c) {
	return rgb2hsl(vec4(c, 1.0)).xyz;
}

// -----------------------------------------------------------------------------------------------
// darkass
// Written from scratch by Dark-Assassin
float round(float value) {
	return floor(value + 0.5);
}

float max_greyscale(vec3 color) {
	return max(color.r, max(color.g, color.b));
}

float max_greyscale(vec4 color) {
	return max_greyscale(color.rgb);
}

vec4 normal_offset(void) {
	vec2 shift = vec2(1.0);
	vec4 offset = vec4(-shift.x, -shift.y, shift.x, shift.y) / world_viewport_size.xyxy;
	return offset;
}

vec4 normal_offset(vec2 vector, bool hide_back_edges) {
	vec4 offset = normal_offset();
	offset *= abs(clamp(vector.xyxy, vec4(-1.0), vec4(1.0)));
	if (hide_back_edges) {
		if (vector.x > 0) {
			offset.x = 0.0;
		}
		if (vector.x < 0) {
			offset.z = 0.0;
		}
		if (vector.y > 0) {
			offset.w = 0.0;
		}
		if (vector.y < 0) {
			offset.y = 0.0;
		}
	}
	return offset;
}

vec4 normal_offset(vec2 vector) {
	return normal_offset(vector, false);
}

vec2 make_normal(vec2 texCoord, vec4 offset, float mask) {
	vec2 diff = vec2(0.0, 0.0);
	{
		float lTex = rgb2hsl(texture2D(tex_fg, texCoord + vec2(offset.x, 0.0))).z * (1.0 - mask);
		float rTex = rgb2hsl(texture2D(tex_fg, texCoord + vec2(offset.z, 0.0))).z * (1.0 - mask);
		float tTex = rgb2hsl(texture2D(tex_fg, texCoord + vec2(0.0, offset.y))).z * (1.0 - mask);
		float bTex = rgb2hsl(texture2D(tex_fg, texCoord + vec2(0.0, offset.w))).z * (1.0 - mask);
		diff += (vec2(
			lTex - rTex,
			bTex - tTex
		) / 2.0);
		float tlTex = rgb2hsl(texture2D(tex_fg, texCoord + vec2(offset.x, offset.y))).z * (1.0 - mask);
		float trTex = rgb2hsl(texture2D(tex_fg, texCoord + vec2(offset.z, offset.y))).z * (1.0 - mask);
		float blTex = rgb2hsl(texture2D(tex_fg, texCoord + vec2(offset.x, offset.w))).z * (1.0 - mask);
		float brTex = rgb2hsl(texture2D(tex_fg, texCoord + vec2(offset.z, offset.w))).z * (1.0 - mask);
		diff += (vec2(
			tlTex - trTex + blTex - brTex,
			blTex - tlTex + brTex - trTex
		) / 2.0);
	}
	return (diff);
}

// Not great, but it works ok enough.
vec2 light_vector(vec2 texCoord) {
	vec4 offset = normal_offset();
	int samples = 16;
	vec2 diff = vec2(0.0);
	for (int i=1; i <= samples; i++) {
		vec2 tDiff = vec2(0.0);
		int j = i * 4;
		float lTex = max_greyscale(texture2D(tex_lights, texCoord + vec2(offset.x, 0.0) * vec2(j)));
		float rTex = max_greyscale(texture2D(tex_lights, texCoord + vec2(offset.z, 0.0) * vec2(j)));
		float tTex = max_greyscale(texture2D(tex_lights, texCoord + vec2(0.0, offset.y) * vec2(j)));
		float bTex = max_greyscale(texture2D(tex_lights, texCoord + vec2(0.0, offset.w) * vec2(j)));
		tDiff -= (vec2(
			lTex - rTex,
			bTex - tTex
		) / 2.0);
		float tlTex = max_greyscale(texture2D(tex_lights, texCoord + vec2(offset.x, offset.y) * vec2(j)));
		float trTex = max_greyscale(texture2D(tex_lights, texCoord + vec2(offset.z, offset.y) * vec2(j)));
		float blTex = max_greyscale(texture2D(tex_lights, texCoord + vec2(offset.x, offset.w) * vec2(j)));
		float brTex = max_greyscale(texture2D(tex_lights, texCoord + vec2(offset.z, offset.w) * vec2(j)));
		tDiff -= (vec2(
			tlTex - trTex + blTex - brTex,
			blTex - tlTex + brTex - trTex
		) / 2.0);
		diff += tDiff;
	}
	return normalize(diff);
}

vec2 glow_vector(vec2 texCoord) {
	vec4 offset = normal_offset();
	vec2 diff = vec2(0.0);
	{
		float lTex = max_greyscale(texture2D(tex_glow, texCoord + vec2(offset.x, 0.0)) - texture2D(tex_glow_unfiltered, texCoord + vec2(offset.x, 0.0)));
		float rTex = max_greyscale(texture2D(tex_glow, texCoord + vec2(offset.z, 0.0)) - texture2D(tex_glow_unfiltered, texCoord + vec2(offset.z, 0.0)));
		float tTex = max_greyscale(texture2D(tex_glow, texCoord + vec2(0.0, offset.y)) - texture2D(tex_glow_unfiltered, texCoord + vec2(0.0, offset.y)));
		float bTex = max_greyscale(texture2D(tex_glow, texCoord + vec2(0.0, offset.w)) - texture2D(tex_glow_unfiltered, texCoord + vec2(0.0, offset.w)));
		diff -= (vec2(
			lTex - rTex,
			tTex - bTex
		) / 2.0);
		float tlTex = max_greyscale(texture2D(tex_glow, texCoord + vec2(offset.x, offset.y)) - texture2D(tex_glow_unfiltered, texCoord + vec2(offset.x, offset.y)));
		float trTex = max_greyscale(texture2D(tex_glow, texCoord + vec2(offset.z, offset.y)) - texture2D(tex_glow_unfiltered, texCoord + vec2(offset.z, offset.y)));
		float blTex = max_greyscale(texture2D(tex_glow, texCoord + vec2(offset.x, offset.w)) - texture2D(tex_glow_unfiltered, texCoord + vec2(offset.x, offset.w)));
		float brTex = max_greyscale(texture2D(tex_glow, texCoord + vec2(offset.z, offset.w)) - texture2D(tex_glow_unfiltered, texCoord + vec2(offset.z, offset.w)));
		diff -= (vec2(
			tlTex - trTex + blTex - brTex,
			tlTex - blTex + trTex - brTex
		) / 2.0);
	}
	return normalize(diff);
}
]],
"varying vec2 tex_coord_fogofwar;",
"data/shaders/post_final.frag"
)

script.append([[

// ============================================================================================================
// Bumpmapping ================================================================================================

	if (bump_settings1.x > 0) {
		float strength = bump_settings2.x;
		float lightness = bump_settings2.y;
		float darkness = bump_settings2.z;

		vec4 light_color = texture2D(tex_lights, tex_coord);
		vec4 glow_color = texture2D(tex_glow, tex_coord_glow);

		vec2 light_vector = light_vector(tex_coord);
		vec2 glow_vector = glow_vector(tex_coord_glow);

		float sky_mask = clamp(sky_ambient_amount * 2.0, 0.0, 1.0);
		float cave_mask = 1.0 - max(sky_mask, clamp(max(max_greyscale(light_color), max_greyscale(glow_color)) * 2.0, 0.0, 1.0));

		vec2 normal = make_normal(tex_coord, normal_offset(light_vector, true), extra_data.a);
		vec2 normal2 = make_normal(tex_coord, normal_offset(glow_vector, true), extra_data.a);
		vec3 bump = vec3(normal.x * light_vector.x + normal.y * light_vector.y) * light_color.rgb + vec3(normal2.x * glow_vector.x + normal2.y * glow_vector.y) * glow_color.rgb * (1.0 - sky_mask) * (1.0 - cave_mask);
		if (bump.r < 0) bump.r *= darkness;
		if (bump.g < 0) bump.g *= darkness;
		if (bump.b < 0) bump.b *= darkness;
		if (bump.r > 0) bump.r *= lightness;
		if (bump.g > 0) bump.g *= lightness;
		if (bump.b > 0) bump.b *= lightness;

		vec2 sky_normal = make_normal(tex_coord, normal_offset(vec2(0.0, -1.0), true), extra_data.a);
		vec3 sky_bump = vec3(-sky_normal.x-sky_normal.y) * sky_light_color.rgb * sky_mask;

		vec2 cave_normal;
		vec3 cave_bump;
		if (bump_settings1.y > 0) {
			cave_normal = make_normal(tex_coord, normal_offset(vec2(0.0, -1.0), true), extra_data.a);
			cave_bump = vec3(-cave_normal.x-cave_normal.y) * 0.5 * cave_mask;
		}

		vec3 bump_color = 1.0 + ((bump + sky_bump + cave_bump) * strength);
		color_fg.rgb *= bump_color;
		
		// Debug stuff
		if (round(bump_settings1.z) == 1) color_fg.rgb = bump_color / 2.0;
		if (round(bump_settings1.z) == 2) color_fg.rgb = vec3((normal.x + normal2.x + 1.0) / 2.0, (normal.y + normal2.y + 1.0) / 2.0, 1.0);
		if (round(bump_settings1.z) == 3) color_fg.rgb = vec3((normal.x + 1.0) / 2.0, (normal.y + 1.0) / 2.0, 1.0);
		if (round(bump_settings1.z) == 4) color_fg.rgb = vec3((normal2.x + 1.0) / 2.0, (normal2.y + 1.0) / 2.0, 1.0);
		if (round(bump_settings1.z) == 5) color_fg.rgb = vec3((light_vector.x + 1.0) / 2.0, (light_vector.y + 1.0) / 2.0, 1.0);
		if (round(bump_settings1.z) == 6) color_fg.rgb = vec3((glow_vector.x + 1.0) / 2.0, (glow_vector.y + 1.0) / 2.0, 1.0);
	}
]],
"color_fg.rgb = mix( color_fg.rgb, fog_color_fg.rgb, fog_amount_fg * fog_amount_multiplier_final );",
"data/shaders/post_final.frag"
)

function HasSettingFlag(setting)
	if (setting ~= nil) then
		if (ModSettingGetNextValue(setting) ~= nil) then
			return ModSettingGetNextValue(setting)
		else
			return false
		end
	else
		print("HasSettingFlag: setting is nil")
	end
end

function UpdateSettings()
	GameSetPostFxParameter("bump_settings1", HasSettingFlag("da_bumpmap.enable_bumpmapping") and 1.0 or 0.0, HasSettingFlag("da_bumpmap.cave_bump") and 1.0 or 0.0, HasSettingFlag("da_bumpmap.debug_mode"), 0.0)
	GameSetPostFxParameter("bump_settings2", ModSettingGetNextValue("da_bumpmap.bump_strength"), ModSettingGetNextValue("da_bumpmap.bump_lightness"), ModSettingGetNextValue("da_bumpmap.bump_darkness"), 0.0)
end

function OnPausedChanged(is_paused, is_inventory_pause)
	UpdateSettings()
end

function OnPlayerSpawned(player_entity)
	UpdateSettings()
end

function OnWorldPostUpdate()

end
