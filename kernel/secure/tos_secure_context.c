#include "tos_k.h"

#define K_SECURE_CTX_STACK_ALIGNMENT               8
#define K_SECURE_CTX_STACK_SEAL_SIZE               8
#define K_SECURE_CTX_STACK_SEAL_VALUE              0xFEF5EDA5

typedef enum secure_ctx_state {
    SECURE_CTX_UNINITIALIZED,
    SECURE_CTX_INITIALIZED
} secure_ctx_state_t;

static k_secure_ctx_t k_secure_ctx[TOS_CFG_NUM_SECURE_CTX];

__STATIC__ k_secure_ctx_handle_t secure_ctx_get(void *owner)
{
    uint32_t i;
    k_secure_ctx_handle_t index = TOS_CFG_NUM_SECURE_CTX;
    for (i = 0; i < TOS_CFG_NUM_SECURE_CTX; i++) {
        if ((k_secure_ctx[i].owner == K_NULL) && (index == TOS_CFG_NUM_SECURE_CTX)) {
            index = i;
        } else if (k_secure_ctx[i].owner == owner) {
            index = TOS_CFG_NUM_SECURE_CTX;
            break;
        }
    }

    return index;
}

__NSC__ __KNL__ void secure_ctx_init(void)
{
    uint32_t i;
    static secure_ctx_state_t state = SECURE_CTX_UNINITIALIZED;
    if (state == SECURE_CTX_UNINITIALIZED && __get_IPSR() != 0) {
        for (i = 0; i < TOS_CFG_NUM_SECURE_CTX; i++) {
            k_secure_ctx[i].sp = K_NULL;
            k_secure_ctx[i].sp_lim = K_NULL;
            k_secure_ctx[i].owner = K_NULL;
        }
        __set_PSP(K_NULL);
        __set_PSPLIM(K_NULL);
        __set_CONTROL((0 << CONTROL_nPRIV_Pos) | (1 << CONTROL_SPSEL_Pos));
        mmheap_init();
        state = SECURE_CTX_INITIALIZED;
    }
}

__NSC__ __KNL__ k_secure_ctx_handle_t secure_ctx_alloc(uint32_t size, void *owner)
{
    k_stack_t *stk_base = K_NULL;
    k_secure_ctx_handle_t index = K_SECURE_CTX_INVALID_ID;
    if (__get_IPSR() != 0) {
        index = secure_ctx_get(owner);
        if (index < TOS_CFG_NUM_SECURE_CTX) {
            stk_base = tos_mmheap_aligned_alloc(size + K_SECURE_CTX_STACK_SEAL_SIZE, K_SECURE_CTX_STACK_ALIGNMENT);
            if (stk_base != K_NULL) {
                k_secure_ctx[index].sp = stk_base + size;
                k_secure_ctx[index].sp_lim = stk_base;
                k_secure_ctx[index].owner = owner;
                *(cpu_data_t *)(k_secure_ctx[index].sp) = K_SECURE_CTX_STACK_SEAL_VALUE;
                *((cpu_data_t *)(k_secure_ctx[index].sp) + 1) = K_SECURE_CTX_STACK_SEAL_VALUE;
                index += 1;
            } else {
                index = K_SECURE_CTX_INVALID_ID;
            }
        } else {
            index = K_SECURE_CTX_INVALID_ID;
        }
    }

    return index;
}

__NSC__ __KNL__ void secure_ctx_free(k_secure_ctx_handle_t handle, void *owner)
{
    if (__get_IPSR() != 0) {
        if ((handle > 0) && (handle <= TOS_CFG_NUM_SECURE_CTX)) {
            handle -= 1;
            if (k_secure_ctx[handle].owner == owner) {
                tos_mmheap_free(k_secure_ctx[handle].sp_lim);
                k_secure_ctx[handle].sp = K_NULL;
                k_secure_ctx[handle].sp_lim = K_NULL;
                k_secure_ctx[handle].owner = K_NULL;
            }
        }
    }
}

__NSC__ __KNL__ void secure_ctx_load(k_secure_ctx_handle_t handle, void *owner)
{
    if (__get_IPSR() != 0) {
        if ((handle > 0) && (handle <= TOS_CFG_NUM_SECURE_CTX)) {
            handle -= 1;
            if ((__get_PSPLIM() == K_NULL) && (k_secure_ctx[handle].owner == owner)) {
                __set_PSP((uint32_t)(k_secure_ctx[handle].sp));
                __set_PSPLIM((uint32_t)(k_secure_ctx[handle].sp_lim));
            }
        }
    }
}

__NSC__ __KNL__ void secure_ctx_save(k_secure_ctx_handle_t handle, void *owner)
{
    if (__get_IPSR() != 0) {
        if ((handle > 0) && (handle <= TOS_CFG_NUM_SECURE_CTX)) {
            handle -= 1;
            if ((__get_PSPLIM() == (uint32_t)(k_secure_ctx[handle].sp_lim)) && (k_secure_ctx[handle].owner == owner)) {
                k_secure_ctx[handle].sp = (k_stack_t *)__get_PSP();
                __set_PSP(K_NULL);
                __set_PSPLIM(K_NULL);
            }
        }
    }
}
