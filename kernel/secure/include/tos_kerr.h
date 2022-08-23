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

#ifndef _TOS_ERR_H_
#define  _TOS_ERR_H_

typedef enum k_err_en {
    K_ERR_NONE                                  = 0u,

    K_ERR_MMHEAP_INVALID_POOL_ADDR              = 800u,
    K_ERR_MMHEAP_INVALID_POOL_SIZE,
    K_ERR_MMHEAP_POOL_OVERFLOW,
    K_ERR_MMHEAP_POOL_ALREADY_EXIST,
    K_ERR_MMHEAP_POOL_NOT_EXIST,

	K_ERR_OBJ_PTR_NULL                          = 1100u,
} k_err_t;

#endif /* _TOS_ERR_H_ */

