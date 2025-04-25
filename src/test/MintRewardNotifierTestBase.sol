// SPDX-License-Identifier: AGPL-3.0-only
// slither-disable-start reentrancy-benign

pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {MintRewardNotifier} from "../notifiers/MintRewardNotifier.sol";
import {PercentAssertions} from "./helpers/PercentAssertions.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Mintable} from "./interfaces/IERC20Mintable.sol";
import {StakerTestBase} from "./StakerTestBase.sol";

abstract contract MintRewardNotifierTestBase is StakerTestBase {
    MintRewardNotifier rewardNotifier;

    function _notifyRewardAmount(uint256 _amount) public override {
        rewardNotifier.notify();
    }
}