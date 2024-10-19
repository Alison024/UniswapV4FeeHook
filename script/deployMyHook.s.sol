// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {Constants} from "./base/Constants.sol";
import {DynamicFeeHook} from "../src/DynamicFeeHook.sol";
import {Create2Deployer} from "../src/Create2Deployer.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";

/// @notice Mines the address and deploys the PointsHook.sol Hook contract
contract DynamicHookScript is Script {
    address public constant CREATE2_DEPLOYER = 0x6C6ef420fD413C54a5600F11Ef6B5e253Cd9D5dE;
    address public constant CREATE2_DEPLOYER_DEF = 0x6C6ef420fD413C54a5600F11Ef6B5e253Cd9D5dE;
    address public constant POOL_MANAGER = 0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A;

    function setUp() public {}

    function run() public {
        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG);
        console.log(address(flags));
        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(POOL_MANAGER);
        // uint256 senderPk = vm.envUint("PK_OLD");
        // address sender = vm.addr(senderPk);
        // console.log(sender);
        // Deploy the hook using CREATE2
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(DynamicFeeHook).creationCode, constructorArgs);
        vm.broadcast();
        DynamicFeeHook hook = new DynamicFeeHook{salt: salt}(IPoolManager(POOL_MANAGER));
        require(address(hook) == hookAddress, "PointsHookScript: hook address mismatch");
    }
}
