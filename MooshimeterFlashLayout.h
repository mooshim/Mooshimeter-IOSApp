/**************************
Mooshimeter iOS App - interface to Mooshimeter wireless multimeter
Copyright (C) 2015  James Whong

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************/

/*******************************

This file contains information about the flash layout of the different application
images in the Mooshimeter.

Note that this file is only visible to the compiler, not the linker.
The linker settings still need to be set separately.

*******************************/

#ifndef Mooshimeter_MooshimeterFlashLayout_h
#define Mooshimeter_MooshimeterFlashLayout_h

#define OAD_IMG_A_PAGE        1
#define OAD_IMG_A_AREA        55
#define OAD_IMG_B_PAGE        8
#define OAD_IMG_B_AREA       (127 - OAD_IMG_A_AREA)

#if defined HAL_IMAGE_B
#define OAD_IMG_D_PAGE        OAD_IMG_A_PAGE
#define OAD_IMG_D_AREA        OAD_IMG_A_AREA
#define OAD_IMG_R_PAGE        OAD_IMG_B_PAGE
#define OAD_IMG_R_AREA        OAD_IMG_B_AREA
#else   //#elif defined HAL_IMAGE_A or a non-BIM-enabled OAD Image-A w/ constants in Bank 1 vice 5.
#define OAD_IMG_D_PAGE        OAD_IMG_B_PAGE
#define OAD_IMG_D_AREA        OAD_IMG_B_AREA
#define OAD_IMG_R_PAGE        OAD_IMG_A_PAGE
#define OAD_IMG_R_AREA        OAD_IMG_A_AREA
#endif

#define FLASH_LOCK_ADDR_WORDS   0xFFFC
#define FLASH_LOCK_SIZE_WORDS   4
#define FLASH_LOCK_SIZE_BYTES   (4*FLASH_LOCK_SIZE_WORDS)
#define FLASH_LOCK_PAGE         (FLASH_LOCK_ADDR_WORDS>>9)
#define FLASH_LOCK_PAGE_OFFSET  ((FLASH_LOCK_ADDR_WORDS & 0x1FF)<<2)

#ifdef __IAR_SYSTEMS_ICC__
#pragma location=0x7FFF0
__no_init __code const unsigned char flash_locks[16];

static const unsigned char desired_flash_locks[] =
{
  0x80, 0xFF, // Bank 0 split
  0xFF, 0xFF, // Bank 1 IMGB
  0xFF, 0xFF, // Bank 2 IMGB
  0xFF, 0xFF, // Bank 3 IMGB
  0xFF, 0xFF, // Bank 4 IMGB
  0x00, 0x00, // Bank 5 IMGA
  0x00, 0x00, // Bank 6 IMGA
  0x00, 
#ifdef REQUIRE_DEBUG_LOCK
0x00, // Bank 7 IMGA and DEBUG LOCK
#else
0x80,
#endif
};
#endif

#endif
