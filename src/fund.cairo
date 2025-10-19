// src/fund.cairo (updated with oracle for total_value)

// In constructor, pass whitelist as Array<(token_addr, asset_id)>, e.g., for BTC, ETH, USDC, USDe with their IDs.
// Pragma oracle address: 0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b (Mainnet)
// _get_token_value assumes price in 8 decimals, amount in token decimals (assume 18 for crypto, adjust if needed for stables).
// central hub for creating and managing the fund: handling deposits, withdrawals (owner-only, with safeguards), balance tracking, and integration hooks for investments and payouts later. Since we're limiting deposits to BTC (e.g., WBTC bridged via Starknet bridges like StarkGate), ETH (native ETH on Starknet), and stables like USDC or USDe (bridged ERC20s), we'll whitelist their contract addresses to enforce that. This reduces complexity and attack surface.
// Use a factory pattern for creating per-user funds (to avoid a monolithic contract), but for MVP, we can make it a single contract with user-specific mappings (e.g., fund_id per owner). Each fund tracks balances per token type.
// Key Assumptions/Design Choices:

// Tokens: Whitelist addresses for WBTC, ETH (Starknet's ETH is the fee token, but for deposits, treat it as a special case or use WETH if needed; for simplicity, we'll use IERC20 for all, with ETH as 0x0 or a placeholder).
// Multi-token support: Use a mapping of token_address to balance.
// Owner: The creator, with AA support for flexible signers.
// Events: For off-chain indexing (e.g., deposits).
// Upgradability: Use proxy pattern if needed, but skip for sketch.
// Security: Reentrancy guards, access controls via OpenZeppelin Cairo (import Ownable).
// ETH Handling: If using native ETH, add a separate deposit_eth with #[l1_handler] or handle via payable, but for uniformity, assume all as ERC20 (use WETH for ETH).
// Extensions: Add invest hook later (dispatcher to Investment Allocator).
// Testing: Deploy with hardcoded whitelist, e.g., Mainnet addresses: USDC (0x053... on Starknet), etc. Use starknet-devnet for local.

#[starknet::contract]
mod Fund {
    use super::super::shared::{FundData, DepositMade, WithdrawalMade, FundCreated, IOracleDispatcher, IOracleDispatcherTrait, IERC20Dispatcher, IERC20DispatcherTrait, BTC_USD_ID, ETH_USD_ID, USDC_USD_ID, USDE_USD_ID, PRAGMA_DECIMALS};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};
    use core::num::traits::Pow;


    #[storage]
    struct Storage {
        funds: Map<ContractAddress, FundData>,  // owner => FundData
        balances: Map<(ContractAddress, ContractAddress), u256>,  // (owner, token) => balance
        token_whitelist: Map<ContractAddress, bool>,  // token_addr => allowed
        token_asset_ids: Map<ContractAddress, felt252>,  // token_addr => Pragma asset_id (e.g., ETH/USD)
        oracle_dispatcher: ContractAddress,  // Pragma oracle address
        owner: ContractAddress,  // Simple owner field
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        FundCreated: FundCreated,
        DepositMade: DepositMade,
        WithdrawalMade: WithdrawalMade,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, oracle_addr: ContractAddress, whitelist_tokens: Array<(ContractAddress, felt252)>) {  // (token, asset_id)
        self.owner.write(owner);
        self.oracle_dispatcher.write(oracle_addr);
        let mut i = 0;
        while i < whitelist_tokens.len() {
            let (token, asset_id) = whitelist_tokens.at(i);
            self.token_whitelist.write(*token, true);
            self.token_asset_ids.write(*token, *asset_id);
            i += 1;
        }
    }

    #[external(v0)]
    fn create_fund(ref self: ContractState) {
        let caller = get_caller_address();
        let zero_addr: ContractAddress = 0.try_into().unwrap();
        assert(self.balances.read((caller, zero_addr)) == 0, 'Fund already exists');  // Simple check
        self.funds.write(caller, FundData { total_value: 0 });
        self.emit(FundCreated { owner: caller });
    }

    #[external(v0)]
    fn deposit(ref self: ContractState, token: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        assert(self.token_whitelist.read(token), 'Token not whitelisted');
        let mut fund = self.funds.read(caller);
        assert(fund.total_value != 0 || self.balances.read((caller, token)) != 0, 'Fund not created');  // Exists check approximation

        let mut token_dispatcher = IERC20Dispatcher { contract_address: token };
        token_dispatcher.transfer_from(caller, get_contract_address(), amount);

        let old_balance = self.balances.read((caller, token));
        self.balances.write((caller, token), old_balance + amount);

        // Update total_value with oracle
        let asset_id = self.token_asset_ids.read(token);
        let added_value = if asset_id == 0 { 0 } else {
            let oracle = IOracleDispatcher { contract_address: self.oracle_dispatcher.read() };
            let price = oracle.get_price(token);
            (amount * price) / 10_u256.pow(PRAGMA_DECIMALS.into())
        };
        fund.total_value += added_value;

        self.funds.write(caller, fund);

        self.emit(DepositMade { owner: caller, token, amount });
    }

    #[external(v0)]
    fn withdraw(ref self: ContractState, token: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        assert(self.owner.read() == caller, 'Not owner');
        let mut fund = self.funds.read(caller);
        let balance = self.balances.read((caller, token));
        assert(balance >= amount, 'Insufficient balance');

        let mut token_dispatcher = IERC20Dispatcher { contract_address: token };
        token_dispatcher.transfer(caller, amount);

        self.balances.write((caller, token), balance - amount);

        // Update total_value
        let asset_id = self.token_asset_ids.read(token);
        let subtracted_value = if asset_id == 0 { 0 } else {
            let oracle = IOracleDispatcher { contract_address: self.oracle_dispatcher.read() };
            let price = oracle.get_price(token);
            (amount * price) / 10_u256.pow(PRAGMA_DECIMALS.into())
        };
        fund.total_value -= subtracted_value;

        self.funds.write(caller, fund);

        self.emit(WithdrawalMade { owner: caller, token, amount });
    }


    #[external(v0)]
    fn get_balance(self: @ContractState, owner: ContractAddress, token: ContractAddress) -> u256 {
        self.balances.read((owner, token))
    }

    #[external(v0)]
    fn get_total_value(self: @ContractState, owner: ContractAddress) -> u256 {
        self.funds.read(owner).total_value
    }

    // Add withdraw_internal for PayoutScheduler if needed
    #[external(v0)]
    fn withdraw_internal(ref self: ContractState, owner: ContractAddress, token: ContractAddress, amount: u256, to: ContractAddress) {
        // Assert caller is PayoutScheduler or similar; for sketch, assume permissioned
        let caller = get_caller_address();
        assert(self.owner.read() == caller, 'Not owner');  // Or add access control
        let mut fund = self.funds.read(owner);
        let balance = self.balances.read((owner, token));
        assert(balance >= amount, 'Insufficient');

        let mut token_dispatcher = IERC20Dispatcher { contract_address: token };
        token_dispatcher.transfer(to, amount);

        self.balances.write((owner, token), balance - amount);
        let asset_id = self.token_asset_ids.read(token);
        let subtracted_value = if asset_id == 0 { 0 } else {
            let oracle = IOracleDispatcher { contract_address: self.oracle_dispatcher.read() };
            let price = oracle.get_price(token);
            (amount * price) / 10_u256.pow(PRAGMA_DECIMALS.into())
        };
        fund.total_value -= subtracted_value;
        self.funds.write(owner, fund);
    }
}