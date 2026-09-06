components {
  id: "enemy_rat"
  component: "/features/enemy_rat/enemy_rat.script"
  properties {
    id: "speed"
    value: "50.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "charge_speed"
    value: "100.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
components {
  id: "rat_attack"
  component: "/assets/sounds/rat_attack.sound"
}
components {
  id: "rat_death"
  component: "/assets/sounds/rat_death.sound"
}
components {
  id: "rat_squeak"
  component: "/assets/sounds/rat_squeak.sound"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"walk\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/features/enemy_rat/enemy_rat.atlas\"\n"
  "}\n"
  ""
  position {
    y: -5.0
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "collisionobject_player"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"enemies\"\n"
  "mask: \"player_enemies\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 10.0\n"
  "  data: 20.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "collisionobject_walls"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"enemies\"\n"
  "mask: \"walls\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 10.0\n"
  "  data: 20.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "collisionobject_bullet"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"enemy\"\n"
  "mask: \"spray\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 10.0\n"
  "  data: 20.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
