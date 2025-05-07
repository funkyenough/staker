// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {BinaryEligibilityOracleEarningPowerCalculatorTestBase} from
  "../../src/test/BinaryEligibilityOracleEarningPowerCalculatorTestBase.sol";
import {BinaryEligibilityOracleEarningPowerCalculator} from
  "src/calculators/BinaryEligibilityOracleEarningPowerCalculator.sol";
import {MintRewardNotifier} from "../../src/notifiers/MintRewardNotifier.sol";
import {IEarningPowerCalculator} from "../../src/interfaces/IEarningPowerCalculator.sol";
import {StakeBase, WithdrawBase} from "../../src/test/StandardTestSuite.sol";
import {Staker} from "../../src/Staker.sol";
import {DeployBinaryEligibilityOracleEarningPowerCalculatorFake} from
  "../fakes/DeployBinaryEligibilityOracleEarningPowerCalculatorFake.sol";
import {ERC20Fake} from "../fakes/ERC20Fake.sol";
import {ERC20VotesMock} from "../mocks/MockERC20Votes.sol";
import {StakerTestBase} from "../../src/test/StakerTestBase.sol";

contract DeployBinaryEligibilityOracleEarningPowerCalculatorTestBase is
  BinaryEligibilityOracleEarningPowerCalculatorTestBase
{
  DeployBinaryEligibilityOracleEarningPowerCalculatorFake DEPLOY_SCRIPT;

  function setUp() public virtual override {
    super.setUp();

    REWARD_TOKEN = new ERC20Fake();
    STAKE_TOKEN = new ERC20VotesMock();
    DEPLOY_SCRIPT =
      new DeployBinaryEligibilityOracleEarningPowerCalculatorFake(REWARD_TOKEN, STAKE_TOKEN);
    (
      IEarningPowerCalculator _earningPowerCalculator,
      Staker _staker,
      address[] memory _rewardNotifiers
    ) = DEPLOY_SCRIPT.run();
    mintRewardNotifier = MintRewardNotifier(_rewardNotifiers[0]);
    calculator = BinaryEligibilityOracleEarningPowerCalculator(address(_earningPowerCalculator));
    staker = _staker;
  }

  // ! or we can override mintamount bound here
}

contract Stake is StakeBase, DeployBinaryEligibilityOracleEarningPowerCalculatorTestBase {
  function setUp()
    public
    override(StakerTestBase, DeployBinaryEligibilityOracleEarningPowerCalculatorTestBase)
  {
    super.setUp();
  }

  function _stake(address _depositor, uint256 _amount, address _delegatee)
    internal
    virtual
    override(StakerTestBase, BinaryEligibilityOracleEarningPowerCalculatorTestBase)
    returns (Staker.DepositIdentifier _depositId)
  {
    return BinaryEligibilityOracleEarningPowerCalculatorTestBase._stake(_depositor, _amount, _delegatee);
  }
}

contract Withdraw is WithdrawBase, DeployBinaryEligibilityOracleEarningPowerCalculatorTestBase {
  function setUp()
    public
    override(StakerTestBase, DeployBinaryEligibilityOracleEarningPowerCalculatorTestBase)
  {
    super.setUp();
  }

  function _stake(address _depositor, uint256 _amount, address _delegatee)
    internal
    virtual
    override(StakerTestBase, BinaryEligibilityOracleEarningPowerCalculatorTestBase)
    returns (Staker.DepositIdentifier _depositId)
  {
    return BinaryEligibilityOracleEarningPowerCalculatorTestBase._stake(_depositor, _amount, _delegatee);
  }

  // !try another approach if I can assume first, then call
  // !call super.testForkFuzz_ClaimRewardAndWithdrawAfterDuration()
  function testForkFuzz_ClaimRewardAndWithdrawAfterDuration(
    address _depositor,
    uint96 _amount,
    address _delegatee,
    uint256 _rewardAmount,
    uint256 _withdrawAmount,
    uint256 _percentDuration
  ) public override {
    _assumeNotZeroAddressOrStaker(_depositor);
    vm.assume(_delegatee != address(0));

    _amount = uint96(_boundMintAmount(_amount));
    vm.assume(_amount != 0); // added for
    _mintStakeToken(_depositor, _amount);
    _rewardAmount = _boundToRealisticReward(_rewardAmount);
    _percentDuration = bound(_percentDuration, 1, 100);

    Staker.DepositIdentifier _depositId = _stake(_depositor, _amount, _delegatee);
    _notifyRewardAmount(_rewardAmount);
    _jumpAheadByPercentOfRewardDuration(_percentDuration);

    uint256 initialRewards = staker.unclaimedReward(_depositId);
    uint256 initialRewardBalance = REWARD_TOKEN.balanceOf(_depositor);

    vm.prank(_depositor);
    staker.claimReward(_depositId);

    uint256 rewardsReceived = REWARD_TOKEN.balanceOf(_depositor) - initialRewardBalance;
    assertEq(staker.unclaimedReward(_depositId), 0);
    assertEq(rewardsReceived, initialRewards);

    _withdrawAmount = bound(_withdrawAmount, 0, _amount);
    _withdraw(_depositor, _depositId, _withdrawAmount);

    uint256 _balance = STAKE_TOKEN.balanceOf(_depositor);
    assertEq(_balance, _withdrawAmount);
  }
}

// contract Stake is StakeBinaryEligibilityOracleEarningPowerCalculatorTestBase,
// DeployBinaryEligibilityOracleEarningPowerCalculatorTestBase {
// }

// contract Withdraw is WithdrawBinaryEligibilityOracleEarningPowerCalculatorTestBase,
// DeployBinaryEligibilityOracleEarningPowerCalculatorTestBase {
// }
