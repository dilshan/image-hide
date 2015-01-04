ImageHide
=========

ImageHide is simple steganography tool using digital image files. ImageHide can be used to embed "subject image" into "cover image" and extract embedded "subject image" from the "cover image". This application support several image file formats and it also support embedding and extraction of gray-scale and color "subject images" from "cover image".

This application is design to work on both Windows and Linux operating systems as console application. 

#### Usage:

`imagehide -e -i -h [parameters] <outputimage>`

* `imagehide`: Filename of the ImageHide executable.
* `-e`: Execute ImageHide application in extraction mode.
* `-i`: Execute ImageHide application in embedding (/insertion) mode.
* `-h`: Show help screen.
* `[parameters]`: This segment can used only with extraction or embedding mode. Valid sequence of parameters are described in below.
* `<outputimage>`: This parameter can used only with extraction or embedding mode. Specify the filename of the output image file with valid file extension.

### Extraction mode

`imagehide -e <srcimage> <out-width> <out-height> <outputimage>`

Extract embedded image from *srcimage* and save to *outputimage*. Use *out-width* and *out-height* parameters to specify the size of the embedded image in pixels. If *out-width* and/or *out-height* parameters are incorrect, output image get clipped or distorted.

#### Example:

`imagehide-x86_64-linux -e ./demo-image.png 125 200 ./output-image.png`

In above example ImageHide extract 125px × 200px image from *demo-image.png* file and save it to *output-image.png*.

### Insertion mode

`imagehide -i <coverimage> <subjectimage> <outputimage>`

Embed subjectimage into coverimage and save in location given by outputimage parameter.

#### Example:

`imagehide-x86_64-linux -i ./barbara-512.png ./message.jpg ./demo-image.png`

In above example ImageHide embed *message.jpg* into *barbara-512.png* image and save embedded image as *demo-image.png*.