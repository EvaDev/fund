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
    use super::super::shared::{FundData, DepositMade, WithdrawalMade, FundCreated, 
        //IOracleDispatcher, IOracleDispatcherTrait,  // TEMPORARILY DISABLED
        IERC20Dispatcher, IERC20DispatcherTrait, 
        IActorDispatcher, IActorDispatcherTrait,
        //BTC_USD_ID, ETH_USD_ID, USDC_USD_ID, USDE_USD_ID,
        //PRAGMA_DECIMALS  // TEMPORARILY DISABLED
        };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};
    use core::num::traits::Pow;
    use core::num::traits::Zero;
    use core::array::ArrayTrait;
    use core::array::Array;


    #[storage]
    struct Storage {
        funds: Map<ContractAddress, FundData>,  // owner => FundData
        balances: Map<(ContractAddress, ContractAddress), u256>,  // (owner, token) => balance
        token_whitelist: Map<ContractAddress, bool>,  // token_addr => allowed
        token_asset_ids: Map<ContractAddress, felt252>,  // token_addr => Pragma asset_id (e.g., ETH/USD)
        // Keep an ordered list of whitelisted tokens for iteration
        token_list: Map<u32, ContractAddress>,
        token_count: u32,
        oracle_dispatcher: ContractAddress,  // Pragma oracle address
        owner: ContractAddress,  // Contract owner
        actor_contract_address: ContractAddress,  // optional actor registry
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        FundCreated: FundCreated,
        DepositMade: DepositMade,
        WithdrawalMade: WithdrawalMade,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, 
        oracle_addr: ContractAddress, 
        actor_contract: ContractAddress) {
        self.owner.write(owner);
        self.oracle_dispatcher.write(oracle_addr);
        self.actor_contract_address.write(actor_contract);
        
        // No hardcoded tokens - they will be added via set_token_asset_id function after deployment
        self.token_count.write(0);
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

        // Update total_value with oracle - TEMPORARILY DISABLED
        // let asset_id = self.token_asset_ids.read(token);
        // let added_value = if asset_id == 0 { 0 } else {
        //     let oracle = IOracleDispatcher { contract_address: self.oracle_dispatcher.read() };
        //     let price = oracle.get_price(token);
        //     (amount * price) / 10_u256.pow(PRAGMA_DECIMALS.into())
        // };
        // fund.total_value += added_value;

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

        // Update total_value - TEMPORARILY DISABLED
        // let asset_id = self.token_asset_ids.read(token);
        // let subtracted_value = if asset_id == 0 { 0 } else {
        //     let oracle = IOracleDispatcher { contract_address: self.oracle_dispatcher.read() };
        //     let price = oracle.get_price(token);
        //     (amount * price) / 10_u256.pow(PRAGMA_DECIMALS.into())
        // };
        // fund.total_value -= subtracted_value;

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
        // let asset_id = self.token_asset_ids.read(token);
        // let subtracted_value = if asset_id == 0 { 0 } else {
        //     let oracle = IOracleDispatcher { contract_address: self.oracle_dispatcher.read() };
        //     let price = oracle.get_price(token);
        //     (amount * price) / 10_u256.pow(PRAGMA_DECIMALS.into())
        // };
        // fund.total_value -= subtracted_value;
        self.funds.write(owner, fund);
    }

    #[external(v0)]
    fn get_fund_data(ref self: ContractState, owner: ContractAddress) -> FundData {
        self.funds.read(owner)
    }

    // Helpers to iterate tokens
    #[external(v0)]
    fn get_token_count(ref self: ContractState) -> u32 { self.token_count.read() }

    #[external(v0)]
    fn get_token_by_index(ref self: ContractState, index: u32) -> ContractAddress { self.token_list.read(index) }

    // Convenience view for front-end: return all whitelisted tokens
    #[external(v0)]
    fn get_whitelisted_tokens(ref self: ContractState) -> Array<ContractAddress> {
        let count = self.token_count.read();
        let mut tokens: Array<ContractAddress> = ArrayTrait::new();
        let mut idx: u32 = 0;
        while idx < count {
            let token = self.token_list.read(idx);
            tokens.append(token);
            idx += 1;
        }
        tokens
    }

    // Admin helpers for oracle address (in case oracle redeployed) - TEMPORARILY DISABLED
    // #[external(v0)]
    // fn get_oracle_address(ref self: ContractState) -> ContractAddress { self.oracle_dispatcher.read() }

    // Only owner can rotate oracle
    // #[external(v0)]
    // fn set_oracle_address(ref self: ContractState, new_addr: ContractAddress) {
    //     assert(self.owner.read() == get_caller_address(), 'Not owner');
    //     self.oracle_dispatcher.write(new_addr);
    // }

    // Actor registry address rotation
    #[external(v0)]
    fn get_actor_contract_address(ref self: ContractState) -> ContractAddress { self.actor_contract_address.read() }

    #[external(v0)]
    fn set_actor_contract_address(ref self: ContractState, new_addr: ContractAddress) {
        assert(self.owner.read() == get_caller_address(), 'Not owner');
        self.actor_contract_address.write(new_addr);
    }

    // Set asset ID for a whitelisted token (owner only)
    #[external(v0)]
    fn set_token_asset_id(ref self: ContractState, token: ContractAddress, asset_id: felt252) {
        assert(self.owner.read() == get_caller_address(), 'Not owner');
        assert(self.token_whitelist.read(token), 'Token not whitelisted');
        self.token_asset_ids.write(token, asset_id);
    }

    // Role check helper (owner or actor with permission)
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn restrict_to_actors(self: @ContractState) {
            let caller = get_caller_address();
            if caller == self.owner.read() { return; }
            let actor_dispatcher = IActorDispatcher { contract_address: self.actor_contract_address.read() };
            let actor = actor_dispatcher.get_actor(caller);
            assert(actor.actor_address.is_non_zero(), 'Caller not registered');
            assert(actor.is_active, 'Caller is inactive');
            assert(actor.can_modify_fund, 'No modify permission');
        }
    }

    // Owner rotation (if needed)
    #[external(v0)]
    fn get_owner(ref self: ContractState) -> ContractAddress { self.owner.read() }

    #[external(v0)]
    fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
        assert(get_caller_address() == self.owner.read(), 'Not owner');
        self.owner.write(new_owner);
    }

    // Transfer beneficiary share proportionally across all tokens
    #[external(v0)]
    fn transfer_beneficiary_share(ref self: ContractState, owner: ContractAddress, beneficiary: ContractAddress, share_percentage: u8) {
        let mut fund = self.funds.read(owner);
        let count = self.token_count.read();
        let mut idx: u32 = 0;
        while idx < count {
            let token = self.token_list.read(idx);
            let balance = self.balances.read((owner, token));
            if balance > 0 {
                // amount = balance * share / 100
                let amount = (balance * share_percentage.into()) / 100_u256;
                if amount > 0 {
                    let mut token_dispatcher = IERC20Dispatcher { contract_address: token };
                    token_dispatcher.transfer(beneficiary, amount);

                    // update storage balance
                    self.balances.write((owner, token), balance - amount);

                    // adjust total value using oracle - TEMPORARILY DISABLED
                    // let asset_id = self.token_asset_ids.read(token);
                    // let subtracted_value = if asset_id == 0 { 0 } else {
                    //     let oracle = IOracleDispatcher { contract_address: self.oracle_dispatcher.read() };
                    //     let price = oracle.get_price(token);
                    //     (amount * price) / 10_u256.pow(PRAGMA_DECIMALS.into())
                    // };
                    // fund.total_value -= subtracted_value;
                }
            }
            idx += 1;
        }
        self.funds.write(owner, fund);
    }
}