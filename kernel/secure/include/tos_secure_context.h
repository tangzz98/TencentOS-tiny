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

#ifndef _TOS_SECURE_CONTEXT_H_
#define  _TOS_SECURE_CONTEXT_H_

__CDECLS_BEGIN

#define K_SECURE_CTX_INVALID_ID     0U

struct k_secure_ctx_st {
    k_stack_t   *sp;
    k_stack_t   *sp_lim;
    void        *owner;
};

__KNL__ void secure_ctx_init(void);

__KNL__ k_secure_ctx_handle_t secure_ctx_alloc(uint32_t size, void *owner);

__KNL__ void secure_ctx_free(k_secure_ctx_handle_t handle, void *owner);

__KNL__ void secure_ctx_load(k_secure_ctx_handle_t handle, void *owner);

__KNL__ void secure_ctx_save(k_secure_ctx_handle_t handle, void *owner);

__CDECLS_END

#endif /* _TOS_SECURE_CONTEXT_H_ */
