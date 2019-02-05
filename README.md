Resoulution independend rendering example
=========================================

This is Godot, purely GDScript implementation of Resolution independent rendering technique described by Charles Loop & Jim Blinn [here](https://www.microsoft.com/en-us/research/wp-content/uploads/2005/01/p1000-loop.pdf). Original code prepared by Mirco Müller, can be found [here](https://bazaar.launchpad.net/~macslow/gl-fragment-curves/trunk/files/14).

Implemented simple shape, no antialiasing yet: [![good image](https://i.gyazo.com/6e4cc4ffaa2c632345d4993c97ff0709.gif)](https://gyazo.com/6e4cc4ffaa2c632345d4993c97ff0709)

This shape drawn with just only 7 trianlges, some calculations required to provide resulting simple shader with params. The shader itself it really light:
```
hader_type canvas_item;

void fragment(){
    if (COLOR.a <= 0.0){
        float v = COLOR.x;
        float w = COLOR.y;
        float t = COLOR.z;
        if (v*v*v - w*t + 0.000001 > 0.0){
            COLOR.rgb = vec3(1.0, 0.0, 0.0);
        } else {
            COLOR.rgb = vec3(0.0, 1.1, 0.0);
        }
        COLOR.a = 0.5;
    }
}
```

There is also no curve splitting for edge cases yet, so there are possible some artefacts: [![artefacts](https://i.gyazo.com/14275d8a8fc31424bf6730b37e35dc54.gif)](https://gyazo.com/14275d8a8fc31424bf6730b37e35dc54)

Tested with godot 3.1.alpha3.
