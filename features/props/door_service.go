components {
  id: "door_service"
  component: "/features/props/doors.script"
}
components {
  id: "door_open"
  component: "/assets/sounds/door_open.sound"
}
components {
  id: "door_closed"
  component: "/assets/sounds/door_closed.sound"
}
embedded_components {
  id: "collisionobject_cursor"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"interactivable\"\n"
  "mask: \"cursor\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      y: -5.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "    id: \"collision_shape\"\n"
  "  }\n"
  "  data: 30.0\n"
  "  data: 50.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "collisionobject_player"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"walls\"\n"
  "mask: \"player\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      y: -36.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 30.0\n"
  "  data: 10.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "sprite_front"
  type: "sprite"
  data: "default_animation: \"door_service_front_idle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/features/props/door.atlas\"\n"
  "}\n"
  ""
  position {
    y: 17.0
    z: 0.2
  }
  scale {
    x: 0.94
    y: 0.94
  }
}
embedded_components {
  id: "sprite_back"
  type: "sprite"
  data: "default_animation: \"door_service_back_idle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 128.0\n"
  "  y: 94.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/features/props/door.atlas\"\n"
  "}\n"
  ""
  position {
    y: -43.0
  }
  scale {
    x: 0.94
    y: 0.94
  }
}
embedded_components {
  id: "collisionobject_npcs"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"walls\"\n"
  "mask: \"npcs\"\n"
  "mask: \"enemies\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      y: -36.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 30.0\n"
  "  data: 10.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
