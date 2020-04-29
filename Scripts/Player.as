
const float acceleration = 0.04f;
const float jump_acceleration = 0.35f;
const float friction = 0.8f;
const float air_friction = 0.9f;
const float eye_height = 1.7f;
const float player_height = 1.85f;
const float player_radius = 0.35f;
const float player_diameter = player_radius*2;
bool fly = false;
bool hold_frustum = false;
float sensitivity = 0.16;

float max_dig_time = 100;
bool block_menu = false;
bool block_menu_created = false;

class Player
{
    Vec3f pos, vel, old_pos;
	CBlob@ blob;
	CPlayer@ player;
    bool onGround = false;
	bool Crouch = false;
	bool Frozen = false;
    //Camera@ camera;
	float dir_x = 0.01f;
	float dir_y = 0.01f;
	Vec3f look_dir;
	bool digging = false;
	Vec3f digging_pos;
	float dig_timer;
	uint8 hand_block = block_stone;

	Player(){}

	void SetBlob(CBlob@ _blob)
	{
		@blob = @_blob;
	}

	void SetPlayer(CPlayer@ _player)
	{
		@player = @_player;
	}

    void Update()
    {
        float temp_friction = friction;
		
		CControls@ c = getControls();
		Driver@ d = getDriver();

		if(c.isKeyJustPressed(KEY_KEY_E))
		{
			block_menu = !block_menu;
		}

		if(block_menu)
		{
			if(!block_menu_created)
			{
				CreateBlockMenu();
				block_menu_created = true;
			}
		}

		if(blob !is null && isWindowActive() && isWindowFocused() && Menu::getMainMenu() is null && !block_menu)
		{
			Vec2f ScrMid = d.getScreenCenterPos();//Vec2f(float(getScreenWidth()) / 2.0f, float(getScreenHeight()) / 2.0f);
			Vec2f dir = (c.getMouseScreenPos() - ScrMid);
			
			dir_x += dir.x*sensitivity;
			if(dir_x < 0) dir_x += 360;
			dir_x = dir_x % 360;
			dir_y = Maths::Clamp(dir_y-(dir.y*sensitivity),-90,90);
			
			Vec2f asuREEEEEE = /*Vec2f(3,26);*/Vec2f(0,0);
			c.setMousePosition(ScrMid-asuREEEEEE);

			look_dir = Vec3f(	Maths::Sin((dir_x)*piboe)*Maths::Cos(dir_y*piboe),
								Maths::Sin(dir_y*piboe),
								Maths::Cos((dir_x)*piboe)*Maths::Cos(dir_y*piboe));

			if(c.isKeyJustPressed(KEY_XBUTTON2)) fly = !fly;
			if(c.isKeyJustPressed(KEY_XBUTTON1)) hold_frustum = !hold_frustum;

			{
				Vec3f hit_pos;
				uint8 check = RaycastWorld(camera.pos, look_dir, 40, hit_pos);
				if(check == Raycast::S_HIT)
				{
					DrawHitbox(int(hit_pos.x), int(hit_pos.y), int(hit_pos.z), 0x88FFC200);
					if(blob.isKeyPressed(key_action2))
					{
						uint8 block = world.map[hit_pos.y][hit_pos.z][hit_pos.x];
						if(block == block_grass)
						{
							server_SetBlock(block_stone, hit_pos);
						}
						else
						{
							Vec3f prev_hit_pos;
							uint8 check2 = RaycastWorld_Previous(camera.pos, look_dir, 40, prev_hit_pos);
							if(check2 == Raycast::S_HIT)
							{
								server_SetBlock(block_stone, prev_hit_pos);
							}
						}
					}
					else if(blob.isKeyPressed(key_action1))
					{
						if(digging)
						{
							if(digging_pos == hit_pos)
							{
								uint8 block = world.map[hit_pos.y][hit_pos.z][hit_pos.x];
								Block@ b = Blocks[block];

								dig_timer += b.dig_speed;
								if(dig_timer >= max_dig_time)
								{
									server_SetBlock(block_air, hit_pos);
									digging = false;
								}
							}
							else
							{
								digging = false;
							}
						}
						else
						{
							digging = true;
							dig_timer = 0;
							digging_pos = hit_pos;
						}
					}
					else if(digging)
					{
						digging = false;
						dig_timer = 0;
					}
				}
				else if(digging)
				{
					digging = false;
					dig_timer = 0;
				}
			}
			
			if(fly)
			{
				Vec3f vel_dir;
				
				if(blob.isKeyPressed(key_up))
				{
					vel_dir.z += 1;
				}
				if(blob.isKeyPressed(key_down))
				{
					vel_dir.z -= 1;
				}
				if(blob.isKeyPressed(key_left))
				{
					vel_dir.x -= 1;
				}
				if(blob.isKeyPressed(key_right))
				{
					vel_dir.x += 1;
				}

				float temp_acceleration = acceleration*6.0f;

				vel_dir.RotateXZ(-dir_x);
				vel_dir.Normalize();
				vel_dir *= temp_acceleration;

				vel += vel_dir;

				if(c.isKeyPressed(KEY_SPACE))
				{
					vel.y += temp_acceleration;
				}
				if(c.isKeyPressed(KEY_LSHIFT))
				{
					vel.y -= temp_acceleration;
				}
			}
			else // do actual movement here
			{
				Vec3f vel_dir;
				
				if(blob.isKeyPressed(key_up))
				{
					vel_dir.z += 1;
				}
				if(blob.isKeyPressed(key_down))
				{
					vel_dir.z -= 1;
				}
				if(blob.isKeyPressed(key_left))
				{
					vel_dir.x -= 1;
				}
				if(blob.isKeyPressed(key_right))
				{
					vel_dir.x += 1;
				}

				float temp_acceleration = acceleration;

				Crouch = false;

				if(onGround)
				{
					if(c.isKeyPressed(KEY_SPACE))
					{
						vel.y += jump_acceleration;
						onGround = false;
					}
					else if(c.isKeyPressed(KEY_LSHIFT))
					{
						Crouch = true;
					}
				}
				else
				{
					temp_friction = air_friction;
				}

				vel_dir.RotateXZ(-dir_x);
				vel_dir.Normalize();
				vel_dir *= temp_acceleration;

				vel += vel_dir;
			}

			if(c.isKeyJustPressed(KEY_KEY_L))
			{
				for(int i = 0; i < chunks_to_render.size(); i++)
				{
					Chunk@ chunk = chunks_to_render[i];
					chunk.rebuild = true;
				}
			}
		}

		if(fly)
		{
			vel.x *= friction;
			vel.z *= friction;
			vel.y *= friction;
		}
		else
		{
			vel.x *= temp_friction;
			vel.z *= temp_friction;

			if(!onGround)
			{
				vel.y = Maths::Max(vel.y-0.04f, -0.3f);
			}
		}

		CollisionResponse(pos, vel);

		//pos = Vec3f(Maths::Clamp(pos.x, player_diameter/1.9f, map_width-player_diameter/1.9f), Maths::Clamp(pos.y, 0, map_height-player_height), Maths::Clamp(pos.z, player_diameter/1.9f, map_depth-player_diameter/1.9f));

		onGround = false;

		Vec3f[] floor_check = {	Vec3f(pos.x-(player_diameter/2.0f), pos.y-0.0002f, pos.z-(player_diameter/2.0f)),
								Vec3f(pos.x+(player_diameter/2.0f), pos.y-0.0002f, pos.z-(player_diameter/2.0f)),
								Vec3f(pos.x+(player_diameter/2.0f), pos.y-0.0002f, pos.z+(player_diameter/2.0f)),
								Vec3f(pos.x-(player_diameter/2.0f), pos.y-0.0002f, pos.z+(player_diameter/2.0f))};
		
		for(int i = 0; i < 4; i++)
		{
			Vec3f temp_pos = floor_check[i];
			if(world.isTileSolid(temp_pos.x, temp_pos.y, temp_pos.z) || temp_pos.y <= 0)
			{
				DrawHitbox(int(temp_pos.x), int(temp_pos.y), int(temp_pos.z), 0x8800FF00);
				onGround = true;
				break;
			}
		}

		float vel_len = vel.Length();

		if(vel.x < 0.0001f && vel.x > -0.0001f) vel.x = 0;
		if(vel.y < 0.0001f && vel.y > -0.0001f) vel.y = 0;
		if(vel.z < 0.0001f && vel.z > -0.0001f) vel.z = 0;
		
		camera.move(pos+Vec3f(0,eye_height,0), false);
		camera.turn(dir_x, dir_y, 0, false);
		camera.tick_update();
    }

	void Serialize(CBitStream@ to_send)
	{
		to_send.write_netid(player.getNetworkID());
		to_send.write_f32(pos.x);
		to_send.write_f32(pos.y);
		to_send.write_f32(pos.z);
		to_send.write_f32(dir_x);
		to_send.write_f32(dir_y);
		to_send.write_bool(Crouch);
		to_send.write_bool(digging);
		if(digging)
		{
			to_send.write_f32(digging_pos.x);
			to_send.write_f32(digging_pos.y);
			to_send.write_f32(digging_pos.z);
			to_send.write_f32(dig_timer);
		}
	}

	void UnSerialize(CBitStream@ received)
	{
		old_pos = pos;
		pos.x = received.read_f32();
		pos.y = received.read_f32();
		pos.z = received.read_f32();
		dir_x = received.read_f32();
		dir_y = received.read_f32();
		Crouch = received.read_bool();
		digging = received.read_bool();
		if(digging)
		{
			digging_pos.x = received.read_f32();
			digging_pos.y = received.read_f32();
			digging_pos.z = received.read_f32();
			dig_timer = received.read_f32();
		}
	}

	void RenderDiggingBlock(Vertex[]&inout verts)
	{
		float u = float(int((dig_timer / max_dig_time) * 8.0f)) / 8.0f;
		float u_step = 1.0f / 8.0f + u;
		float s = 0.02f;
		
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z-s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z-s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z-s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z-s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z+1+s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z+1+s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z+1+s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z+1+s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z+1+s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z+1+s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z-s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z-s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z-s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z-s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z+1+s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z+1+s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z-s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z+1+s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z+1+s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z-s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z+1+s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z-s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z-s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z+1+s,	u_step,	1,	color_white));
	}

	void CreateBlockMenu()
	{
		getHUD().ClearMenus(true);
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), null, Vec2f(8, 5), "Pick a block.");
		
		if (menu !is null)
		{
			CBitStream exitParams;
			exitParams.write_netid(getLocalPlayer().getNetworkID());
			menu.SetDefaultCommand(getRules().getCommandID("pick_block_reset"), exitParams);
			menu.deleteAfterClick = true;
			for (int i = 1; i < block_counter; i++)
			{
				bool current_picked = (i == hand_block);
				CBitStream params;
				params.write_netid(getLocalPlayer().getNetworkID());
				params.write_u8(i);
				CGridButton@ button = menu.AddButton(Blocks[i].name+"_Icon", "Pick a block.", getRules().getCommandID("pick_block"), Vec2f(1,1), params);
				if(button !is null)
				{
					button.selectOnClick = true;
					//button.deleteAfterClick = true;
					button.clickable = true;
					if(current_picked)
					{
						button.clickable = false;
						button.SetSelected(2);
					}
					button.SetHoverText(Blocks[i].name+"."+(current_picked ? " (currently picked)" : ""));
				}
			}
		}
	}
}

void CollisionResponse(Vec3f&inout position, Vec3f&inout velocity)
{
	//x collision
	Vec3f xPosition(position.x + velocity.x, position.y, position.z);
	if (isColliding(position, xPosition))
	{
		if (velocity.x > 0)
		{
			position.x = Maths::Ceil(position.x + player_radius) - player_radius - 0.0001f;
		}
		else if (velocity.x < 0)
		{
			position.x = Maths::Floor(position.x - player_radius) + player_radius + 0.0001f;
		}
		velocity.x = 0;
	}
	position.x += velocity.x;

	//z collision
	Vec3f zPosition(position.x, position.y, position.z + velocity.z);
	if (isColliding(position, zPosition))
	{
		if (velocity.z > 0)
		{
			position.z = Maths::Ceil(position.z + player_radius) - player_radius - 0.0001f;
		}
		else if (velocity.z < 0)
		{
			position.z = Maths::Floor(position.z - player_radius) + player_radius + 0.0001f;
		}
		velocity.z = 0;
	}
	position.z += velocity.z;

	//y collision
	Vec3f yPosition(position.x, position.y + velocity.y, position.z);
	if (isColliding(position, yPosition))
	{
		if (velocity.y > 0)
		{
			position.y = Maths::Ceil(position.y + player_height) - player_height - 0.0001f;
		}
		else if (velocity.y < 0)
		{
			position.y = Maths::Floor(position.y) + 0.0001f;
		}
		velocity.y = 0;
	}
	position.y += velocity.y;
}

bool isColliding(const Vec3f&in position, const Vec3f&in next_position)
{
	float x_negative = next_position.x - player_radius; if(x_negative < 0) x_negative -= 1;
	int x_end = next_position.x + player_radius;
	float z_negative = next_position.z - player_radius; if(z_negative < 0) z_negative -= 1;
	int z_end = next_position.z + player_radius;
	float y_negative = next_position.y; if(y_negative < 0) y_negative -= 1;
	int y_end = next_position.y + player_height;

	for (int y = y_negative; y <= y_end; y++)
	{
		for (int z = z_negative; z <= z_end; z++)
		{
			for (int x = x_negative; x <= x_end; x++)
			{
				if ( //ignore voxels the player is currently inside
					x >= Maths::Floor(position.x - player_diameter / 2.0f) && x < Maths::Ceil(position.x + player_diameter / 2.0f) &&
					y >= Maths::Floor(position.y) && y < Maths::Ceil(position.y + player_height) &&
					z >= Maths::Floor(position.z - player_diameter / 2.0f) && z < Maths::Ceil(position.z + player_diameter / 2.0f))
				{
					// dont actually ignore, try pushing away (meh, later)
					continue;
				}

				if (world.isTileSolidOrOOB(x, y, z))
				{
					DrawHitbox(x, y, z, 0x8800FF00);
					return true;
				}
			}
		}
	}
	return false;
}