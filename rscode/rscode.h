/*
 * qrencode - QR Code encoder
 *
 * Reed solomon encoder. This code is taken from Phil Karn's libfec then
 * editted and packed into a pair of .c and .h files.
 *
 * Copyright (C) 2002, 2003, 2004, 2006 Phil Karn, KA9Q
 * (libfec is released under the GNU Lesser General Public License.)
 *
 * Copyright (C) 2006-2011 Kentaro Fukuchi <kentaro@fukuchi.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 */

#ifndef __RSCODE_H__
#define __RSCODE_H__

#define RS_SYMSIZE			5
#define RS_GFPOLY			0x25
#define RS_FCR				1
#define RS_PRIM				1
#define RS_NROOTS			8
#define RS_DATA_LEN			10
#define RS_TOTAL_LEN		(RS_DATA_LEN + RS_NROOTS)
#define RS_PAD				((1<<RS_SYMSIZE) - 1 - RS_TOTAL_LEN)

/*
 * General purpose RS codec, 8-bit symbols.
 */

typedef struct _RS RS;

extern RS *init_rs(int symsize, int gfpoly, int fcr, int prim, int nroots, int pad);
extern void encode_rs_char(RS *rs, const unsigned char *data, unsigned char *parity);
extern int  decode_rs_char(RS *rs, unsigned char *data, int *eras_pos, int no_eras);
extern void free_rs_char(RS *rs);
extern void free_rs_cache(void);

#endif /* __RSCODE_H__ */
