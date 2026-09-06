components {
  id: "bookcase"
  component: "/features/furniture/bookcase.script"
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
  "      y: -12.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "    id: \"collision_shape\"\n"
  "  }\n"
  "  data: 42.5\n"
  "  data: 30.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "sprite_books"
  type: "sprite"
  data: "default_animation: \"bookcase_books_01\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 128.0\n"
  "  y: 128.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/features/furniture/furniture.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.01
  }
}
