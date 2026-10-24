# Car materials

Built-in image generation; original atlas created for this project. Runtime asset: car_materials.jpg, 1024 × 1024, mipmapped. Quadrants: silver headlamp reflector / tire rubber / honeycomb grille / white pearl paint. No third-party vehicle photos or logos.

Prompt: “Photorealistic game car material texture atlas, square, precise edge-to-edge 2 by 2 grid of equal squares, no gaps or text. Upper left neutral silver automotive reflector with dense prismatic diamond facets. Upper right charcoal tire rubber with fine grain and shallow longitudinal tread grooves. Lower left black automotive honeycomb grille. Lower right pale silver-white pearl paint with fine metallic flake. Straight-on orthographic, flat even lighting, clean factory-fresh materials. No perspective, vignettes, logos, objects or watermark.”

Shader car_material.gdshader samples the four quadrants using object-space triplanar projection. The paint sample is blended subtly to retain body color. This is an albedo/detail atlas, not a measured PBR scan; there are no authored normal maps in this version.
