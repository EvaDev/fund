// src/shared.cairo (updated with additions for PayoutScheduler)

use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};
use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
use starknet::syscalls::call_contract_syscall;
use starknet::SyscallResultTrait;
use core::array::ArrayTrait;
use core::option::OptionTrait;
use core::serde::Serde;
use core::traits::Into;

// Constants
pub const PING_INTERVAL: u64 = 2592000; // 30 days in seconds (approx)
pub const PAYOUT_INTERVAL: u64 = 2592000; // Monthly, approx 30 days
pub const PRAGMA_DECIMALS: u32 = 8; // Common for Pragma prices
pub const ETH_USD_ID: felt252 = 19514442401534788; // selector!("ETH/USD")
pub const BTC_USD_ID: felt252 = 0x194e6e781bbc476635a2247fb9f3df6284d96acc6ca78efc94a1f7295ef1c92; // selector!("BTC/USD")
pub const USDC_USD_ID: felt252 = 0x134bb924829bcd95051e583b1b751e75b47c6378406b0cd773ae7e602de88b5; // selector!("USDC/USD")
pub const USDE_USD_ID: felt252 = 0x291c78e2caa8dc0ae6a489a2a090210e8be4bda8ada1f5bcb43520b2b3570d3; // selector!("USDE/USD")

// Enums
#[derive(Drop, Serde, starknet::Store, Copy)]
#[allow(starknet::store_no_default_variant)]
pub enum ProtocolType {
    Lending: (),   // e.g., zkLend, Nostra
    Liquidity: (), // e.g., Ekubo LP
    Yield: (),     // e.g., Yearn-like vaults
    Idle: (),      // No investment
}

// Structs
#[derive(Drop, Serde, starknet::Store, Copy)]
pub struct FundData {
    pub total_value: u256,                     // Approximate total in USD via oracle
}

#[derive(Drop, Serde, starknet::Store, Copy)]
pub struct Beneficiary {
    pub addr: ContractAddress,
    pub share: u8,  // Percentage 0-100
    pub prefs: PayoutPrefs,
}

#[derive(Drop, Serde, starknet::Store, Copy)]
pub struct PayoutPrefs {
    pub stable_pct: u8,
    pub bitrefill_pct: u8,
    pub token_pct: u8,
    pub token_addr: ContractAddress,  // For the token part
}


#[derive(Drop, Serde, starknet::Store, Copy)]
pub struct Allocation {
    pub protocol_addr: ContractAddress,
    pub percentage: u8,  // 0-100
    pub protocol_type: ProtocolType,
}

#[derive(Drop, Serde, starknet::Store, Copy)]
pub struct PayoutSchedule {
    pub last_payout: u64,
    pub interval: u64,  // In seconds
    pub available_funds: u256,  // e.g., yields to distribute
}

// Events (shared across contracts)
#[derive(Drop, starknet::Event)]
pub enum SharedEvent {
    FundCreated: FundCreated,
    DepositMade: DepositMade,
    WithdrawalMade: WithdrawalMade,
    BeneficiaryAdded: BeneficiaryAdded,
    InheritanceTriggered: InheritanceTriggered,
    PayoutExecuted: PayoutExecuted,
    BitrefillEvent: BitrefillEvent,
    // Add more as needed
}

#[derive(Drop, starknet::Event)]
pub struct FundCreated {
    #[key]
    pub owner: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct DepositMade {
    #[key]
    pub owner: ContractAddress,
    pub token: ContractAddress,
    pub amount: u256,
}

#[derive(Drop, starknet::Event)]
pub struct WithdrawalMade {
    #[key]
    pub owner: ContractAddress,
    pub token: ContractAddress,
    pub amount: u256,
}

#[derive(Drop, starknet::Event)]
pub struct BeneficiaryAdded {
    #[key]
    pub owner: ContractAddress,
    pub beneficiary_addr: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct InheritanceTriggered {
    #[key]
    pub owner: ContractAddress,
    pub beneficiary_addr: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct PayoutExecuted {
    #[key]
    pub owner: ContractAddress,
    #[key]
    pub beneficiary: ContractAddress,
    pub amount: u256,
}

#[derive(Drop, starknet::Event)]
pub struct BitrefillEvent {
    #[key]
    pub beneficiary: ContractAddress,
    pub amount: u256,
    pub details: ByteArray,  // For off-chain relayer
}

// Dispatcher Interfaces (for cross-contract calls)
#[derive(Copy, Drop)]
pub struct IFundDispatcher {
    pub contract_address: ContractAddress,
}

#[starknet::interface]
pub trait IFundDispatcherTrait<T> {
    fn get_balance(self: @T, owner: ContractAddress, token: ContractAddress) -> u256;
    fn withdraw_internal(ref self: T, owner: ContractAddress, token: ContractAddress, amount: u256, to: ContractAddress);
    // Expand as needed
}

impl IFundDispatcherImpl of IFundDispatcherTrait<IFundDispatcher> {
    fn get_balance(self: @IFundDispatcher, owner: ContractAddress, token: ContractAddress) -> u256 {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@owner, ref calldata);
        Serde::serialize(@token, ref calldata);
        let mut res = call_contract_syscall(
            *self.contract_address,
            selector!("get_balance"),
            calldata.span()
        ).unwrap_syscall();
        Serde::<u256>::deserialize(ref res).unwrap()
    }

    fn withdraw_internal(ref self: IFundDispatcher, owner: ContractAddress, token: ContractAddress, amount: u256, to: ContractAddress) {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@owner, ref calldata);
        Serde::serialize(@token, ref calldata);
        Serde::serialize(@amount, ref calldata);
        Serde::serialize(@to, ref calldata);
        call_contract_syscall(
            self.contract_address,
            selector!("withdraw_internal"),  // Assume added to Fund for internal calls
            calldata.span()
        ).unwrap_syscall();
    }
}

#[derive(Copy, Drop)]
pub struct IBeneficiaryDispatcher {
    pub contract_address: ContractAddress,
}

#[starknet::interface]
pub trait IBeneficiaryDispatcherTrait<T> {
    fn get_beneficiaries(self: @T, owner: ContractAddress) -> Array<Beneficiary>;
}

impl IBeneficiaryDispatcherImpl of IBeneficiaryDispatcherTrait<IBeneficiaryDispatcher> {
    fn get_beneficiaries(self: @IBeneficiaryDispatcher, owner: ContractAddress) -> Array<Beneficiary> {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@owner, ref calldata);
        let mut res = call_contract_syscall(
            *self.contract_address,
            selector!("get_beneficiaries"),
            calldata.span()
        ).unwrap_syscall();
        Serde::<Array<Beneficiary>>::deserialize(ref res).unwrap()
    }
}

#[derive(Copy, Drop)]
pub struct IOracleDispatcher {
    pub contract_address: ContractAddress,
}

#[starknet::interface]
pub trait IOracleDispatcherTrait<T> {
    fn get_price(self: @T, token: ContractAddress) -> u256;  // e.g., in USD
}

impl IOracleDispatcherImpl of IOracleDispatcherTrait<IOracleDispatcher> {
    fn get_price(self: @IOracleDispatcher, token: ContractAddress) -> u256 {
        // Simplified oracle - returns a mock price for now
        // In production, this would call the actual oracle contract
        if token == 0x123.try_into().unwrap() {  // Mock token address
            200000000  // Mock price in 8 decimals
        } else {
            100000000  // Default mock price
        }
    }
}

#[derive(Copy, Drop)]
pub struct IERC20Dispatcher {
    pub contract_address: ContractAddress,
}

#[starknet::interface]
pub trait IERC20DispatcherTrait<T> {
    fn transfer(ref self: T, recipient: ContractAddress, amount: u256);
    fn transfer_from(ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256);
}

impl IERC20DispatcherImpl of IERC20DispatcherTrait<IERC20Dispatcher> {
    fn transfer(ref self: IERC20Dispatcher, recipient: ContractAddress, amount: u256) {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@recipient, ref calldata);
        Serde::serialize(@amount, ref calldata);
        call_contract_syscall(
            self.contract_address,
            selector!("transfer"),
            calldata.span()
        ).unwrap_syscall();
    }

    fn transfer_from(ref self: IERC20Dispatcher, sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@sender, ref calldata);
        Serde::serialize(@recipient, ref calldata);
        Serde::serialize(@amount, ref calldata);
        call_contract_syscall(
            self.contract_address,
            selector!("transfer_from"),
            calldata.span()
        ).unwrap_syscall();
    }
}

#[derive(Copy, Drop)]
pub struct IDEXDispatcher {
    pub contract_address: ContractAddress,
}

#[starknet::interface]
pub trait IDEXDispatcherTrait<T> {
    fn swap(ref self: T, from_token: ContractAddress, to_token: ContractAddress, amount_in: u256) -> u256;
}

impl IDEXDispatcherImpl of IDEXDispatcherTrait<IDEXDispatcher> {
    fn swap(ref self: IDEXDispatcher, from_token: ContractAddress, to_token: ContractAddress, amount_in: u256) -> u256 {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@from_token, ref calldata);
        Serde::serialize(@to_token, ref calldata);
        Serde::serialize(@amount_in, ref calldata);
        let mut res = call_contract_syscall(
            self.contract_address,
            selector!("swap"),  // Assume DEX has this
            calldata.span()
        ).unwrap_syscall();
        Serde::<u256>::deserialize(ref res).unwrap()
    }
}

#[derive(Copy, Drop)]
pub struct INFTDispatcher {
    pub contract_address: ContractAddress,
}

#[starknet::interface]
pub trait INFTDispatcherTrait<T> {
    fn mint_voucher(ref self: T, to: ContractAddress, amount: u256, details: ByteArray);
}

impl INFTDispatcherImpl of INFTDispatcherTrait<INFTDispatcher> {
    fn mint_voucher(ref self: INFTDispatcher, to: ContractAddress, amount: u256, details: ByteArray) {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@to, ref calldata);
        Serde::serialize(@amount, ref calldata);
        Serde::serialize(@details, ref calldata);
        call_contract_syscall(
            self.contract_address,
            selector!("mint_voucher"),
            calldata.span()
        ).unwrap_syscall();
    }
}

// Add more dispatchers as needed