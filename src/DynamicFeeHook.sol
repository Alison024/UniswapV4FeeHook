// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {Pool} from "v4-core/src/libraries/Pool.sol";
import {Hooks, IHooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

contract DynamicFeeHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    event PoolFeeUpdated(PoolId poolId, uint24 fee);

    uint256 public constant MIN_LIQUIDITY = 1e24;
    uint256 public constant MAX_LIQUIDITY = 1e28;
    uint256 public PRECISION = 1e18;
    uint24 public constant INITIAL_FEE = 100; // default fee 0.05%
    uint24 public constant MIN_FEE = 100; // min fee 0.01%
    uint24 public constant MAX_FEE = 5000; // max fee 0.5%
    mapping(uint256 poolId => uint256 fee) public poolsFees;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function afterInitialize(address, PoolKey calldata key, uint160, int24, bytes calldata)
        external
        override
        returns (bytes4)
    {
        uint24 initialFee = INITIAL_FEE;
        poolManager.updateDynamicLPFee(key, initialFee);
        return IHooks.afterInitialize.selector;
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint128 liquidity = poolManager.getLiquidity(key.toId());
        uint24 newFee = getFee(liquidity);
        poolManager.updateDynamicLPFee(key, newFee);
        emit PoolFeeUpdated(key.toId(), newFee);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function getFee(uint128 _liquidity) public view returns (uint24) {
        uint256 maxLiq = MAX_LIQUIDITY;
        uint24 minFee = MIN_FEE;
        if (maxLiq < _liquidity) return minFee;
        uint24 maxFee = MAX_FEE;
        uint256 minLiq = MIN_LIQUIDITY;
        if (minLiq > _liquidity) return maxFee;
        uint256 prec = PRECISION;
        return maxFee - uint24(((maxFee - minFee) * (_liquidity * prec / (maxLiq - minLiq)) / prec));
    }
}
