components {
  id: "spawn_enemies"
  component: "/main/spawn_enemies.script"
  properties {
    id: "spawn_interval"
    value: "3.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "enemy_type"
    value: "mix"
    type: PROPERTY_TYPE_HASH
  }
  properties {
    id: "reactivate_delay"
    value: "10.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "use_nest_ranges"
    value: "true"
    type: PROPERTY_TYPE_BOOLEAN
  }
}
components {
  id: "nest"
  component: "/features/enemies/nest.script"
}
components {
  id: "nest_plague_destruction"
  component: "/assets/sounds/nest_plague_destruction.sound"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"spawn\"\n"
  "mask: \"player_spawn\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 50.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "collisionobject_interact"
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
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "    id: \"collision_shape\"\n"
  "  }\n"
  "  data: 10.0\n"
  "  data: 10.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"nest_idle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 64.0\n"
  "  y: 64.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/features/props/props.atlas\"\n"
  "}\n"
  ""
  position {
    y: 19.0
  }
  scale {
    x: 0.5
    y: 0.5
  }
}
embedded_components {
  id: "bug_factory"
  type: "factory"
  data: "prototype: \"/features/enemy_cockroach/enemy_cockroach.go\"\n"
  ""
}
embedded_components {
  id: "rat_factory"
  type: "factory"
  data: "prototype: \"/features/enemy_rat/enemy_rat.go\"\n"
  ""
}
