components {
  id: "anim_script"
  component: "/intro/intro_animation.script"
}
embedded_components {
  id: "sprite_background"
  type: "sprite"
  data: "default_animation: \"intro_sprite\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/textures/intro/intro.atlas\"\n"
  "}\n"
  ""
  position {
    x: 640.0
    y: 384.0
  }
}
embedded_components {
  id: "title_es"
  type: "label"
  data: "size {\n"
  "  x: 400.0\n"
  "  y: 32.0\n"
  "}\n"
  "color {\n"
  "  x: 0.6\n"
  "  y: 0.2\n"
  "  z: 0.0\n"
  "}\n"
  "line_break: true\n"
  "text: \"Un d\\303\\255a en el museo\"\n"
  "font: \"/assets/fonts/title.font\"\n"
  "material: \"/assets/fonts/font-df-tile.material\"\n"
  ""
  position {
    x: 640.0
    y: 500.0
    z: 1.0
  }
  scale {
    x: 2.0
    y: 2.0
    z: 2.0
  }
}
embedded_components {
  id: "title_en"
  type: "label"
  data: "size {\n"
  "  x: 400.0\n"
  "  y: 32.0\n"
  "}\n"
  "color {\n"
  "  x: 0.6\n"
  "  y: 0.2\n"
  "  z: 0.0\n"
  "}\n"
  "line_break: true\n"
  "text: \"A day at the museum\"\n"
  "font: \"/assets/fonts/title.font\"\n"
  "material: \"/assets/fonts/font-df-tile.material\"\n"
  ""
  position {
    x: 640.0
    y: 500.0
    z: 1.0
  }
  scale {
    x: 2.0
    y: 2.0
    z: 2.0
  }
}
embedded_components {
  id: "label_credits"
  type: "label"
  data: "size {\n"
  "  x: 128.0\n"
  "  y: 32.0\n"
  "}\n"
  "color {\n"
  "  x: 0.9254902\n"
  "  y: 0.69411767\n"
  "  z: 0.52156866\n"
  "}\n"
  "text: \"nosinmipixel 2026\"\n"
  "font: \"/assets/fonts/dialogs.font\"\n"
  "material: \"/assets/fonts/font-df-tile.material\"\n"
  ""
  position {
    x: 640.0
    y: 73.0
  }
  scale {
    x: 0.3
    y: 0.3
  }
}
