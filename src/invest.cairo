// src/invest.cairo

// Invest (simplified for MVP)
// Removed Ownable, Vec storage and validations.
// set_allocations accepts input and emits AllocationSet; invest emits placeholder InvestmentMade.
// Imports trimmed; added StoragePointerWriteAccess for constructor writes.

#[starknet::contract]
mod Invest {
    use super::super::shared::{Allocation};
    use starknet::{ContractAddress, get_caller_address};
    use core::array::ArrayTrait;
    use core::num::traits::Zero;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::super::shared::{IActorDispatcher, IActorDispatcherTrait, ACTOR_FUNDMANAGER};

    #[storage]
    struct Storage {
        fund_dispatcher: ContractAddress,
        oracle_dispatcher: ContractAddress,
        owner: ContractAddress,
        actor_contract_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AllocationSet: AllocationSet,
        InvestmentMade: InvestmentMade,
        YieldsHarvested: YieldsHarvested,
    }

    #[derive(Drop, starknet::Event)]
    struct AllocationSet {
        #[key]
        owner: ContractAddress,
        allocations_count: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct InvestmentMade {
        #[key]
        owner: ContractAddress,
        protocol: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct YieldsHarvested {
        #[key]
        owner: ContractAddress,
        total_yield: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, fund_addr: ContractAddress, oracle_addr: ContractAddress, actor_contract: ContractAddress) {
        self.owner.write(owner);
        self.fund_dispatcher.write(fund_addr);
        self.oracle_dispatcher.write(oracle_addr);
        self.actor_contract_address.write(actor_contract);
    }

    // Admin helpers
    #[external(v0)]
    fn get_fund_address(ref self: ContractState) -> ContractAddress { self.fund_dispatcher.read() }

    #[external(v0)]
    fn set_fund_address(ref self: ContractState, new_addr: ContractAddress) {
        assert(get_caller_address() == self.owner.read(), 'Not owner');
        self.fund_dispatcher.write(new_addr);
    }

    #[external(v0)]
    fn get_oracle_address(ref self: ContractState) -> ContractAddress { self.oracle_dispatcher.read() }

    #[external(v0)]
    fn set_oracle_address(ref self: ContractState, new_addr: ContractAddress) {
        assert(get_caller_address() == self.owner.read(), 'Not owner');
        self.oracle_dispatcher.write(new_addr);
    }

    #[external(v0)]
    fn get_owner(ref self: ContractState) -> ContractAddress { self.owner.read() }

    #[external(v0)]
    fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
        assert(get_caller_address() == self.owner.read(), 'Not owner');
        self.owner.write(new_owner);
    }

    // ActorRegistry wiring
    #[external(v0)]
    fn get_actor_contract_address(ref self: ContractState) -> ContractAddress { self.actor_contract_address.read() }

    #[external(v0)]
    fn set_actor_contract_address(ref self: ContractState, new_addr: ContractAddress) {
        assert(get_caller_address() == self.owner.read(), 'Not owner');
        self.actor_contract_address.write(new_addr);
    }

    #[external(v0)]
    fn set_allocations(ref self: ContractState, allocs: Array<Allocation>) {
        let caller = get_caller_address();
        let len = allocs.len();
        // MVP: accept any input; persistence/validation can be added later
        let _ignore = allocs;
        self.emit(AllocationSet { owner: caller, allocations_count: len });
    }

    #[external(v0)]
    fn invest(ref self: ContractState) {
        self.restrict_to_fund_manager();
        let caller = get_caller_address();
        // MVP: no-op investment; emit placeholder event
        self.emit(InvestmentMade { owner: caller, protocol: 0.try_into().unwrap(), amount: 0 });
    }

    #[external(v0)]
    fn harvest_yields(ref self: ContractState) {
        // Similar loop over allocs, call harvest/claim on each protocol, transfer back to fund
        // Update total_value via oracle
    }

    #[external(v0)]
    fn get_allocations(ref self: ContractState, _owner: ContractAddress) -> Array<Allocation> {
        // MVP: return empty list
        let mut arr: Array<Allocation> = ArrayTrait::new();
        arr
    }

    // Internal role guard: Fund Manager (or owner) only
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn restrict_to_fund_manager(self: @ContractState) {
            let caller = get_caller_address();
            if caller == self.owner.read() { return; }
            let actor_disp = IActorDispatcher { contract_address: self.actor_contract_address.read() };
            let actor = actor_disp.get_actor(caller);
            assert(actor.actor_address.is_non_zero(), 'Caller not registered');
            assert(actor.is_active, 'Caller inactive');
            assert(actor.actor_role == ACTOR_FUNDMANAGER, 'Not FundManager');
        }
    }
}