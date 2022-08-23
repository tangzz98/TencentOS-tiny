/*----------------------------------------------------------------------------
 * Tencent is pleased to support the open source community by making TencentOS
 * available.
 *
 * Copyright (C) 2019 THL A29 Limited, a Tencent company. All rights reserved.
 * If you have downloaded a copy of the TencentOS binary from Tencent, please
 * note that the TencentOS binary is licensed under the BSD 3-Clause License.
 *
 * If you have downloaded a copy of the TencentOS source code from Tencent,
 * please note that TencentOS source code is licensed under the BSD 3-Clause
 * License, except for the third-party components listed below which are
 * subject to different license terms. Your integration of TencentOS into your
 * own projects may require compliance with the BSD 3-Clause License, as well
 * as the other licenses applicable to the third-party components included
 * within TencentOS.
 *---------------------------------------------------------------------------*/

#ifndef _TOS_KLIB_H_
#define  _TOS_KLIB_H_

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define __MACRO_BEGIN        do {
#define __MACRO_END          } while (0)

#define TOS_OFFSET_OF_FIELD(type, field)    \
    ((uint32_t)&(((type *)0)->field))

#define TOS_CONTAINER_OF_FIELD(ptr, type, field)    \
    ((type *)((uint8_t *)(ptr) - TOS_OFFSET_OF_FIELD(type, field)))

#define TOS_COUNT_OF(array)             (sizeof(array) / sizeof(array[0]))

#define TOS_PTR_SANITY_CHECK(ptr)               \
    __MACRO_BEGIN                               \
        if (unlikely(!(ptr))) {                 \
            return K_ERR_OBJ_PTR_NULL;          \
        }                                       \
    __MACRO_END

#define TOS_PTR_SANITY_CHECK_RC(ptr, return_code)           \
    __MACRO_BEGIN                                           \
        if (unlikely(!(ptr))) {                             \
            return return_code;                             \
        }                                                   \
    __MACRO_END

#if TOS_CFG_LIBC_PRINTF_EN > 0u
#define LIBC_PRINTF             printf
#else
#define LIBC_PRINTF(...)
#endif

// currently we use default microlib supplied by mdk
#define tos_kprintf(...)         LIBC_PRINTF(__VA_ARGS__);

#define tos_kprintln(...)       \
    LIBC_PRINTF(__VA_ARGS__);   \
    LIBC_PRINTF("\n");

#define TOS_ASSERT(exp) TOS_ASSERT_AUX(exp, __FUNCTION__, __LINE__)

#endif /* _TOS_KLIB_H_ */

