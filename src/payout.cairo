// src/payout.cairo

// Payout (simplified for MVP)
// Stripped Ownable/DEX/NFT/SharedEvent.
// Storage: schedules, fund_dispatcher, beneficiary_dispatcher.
// constructor(fund_addr, ben_addr).
// execute_payout pays token portion only via Fund.withdraw_internal; emits PayoutExecuted.
// set_schedule, get_schedule, set_available_funds exposed.

#[starknet::contract]
mod Payout {
    use super::super::shared::{PayoutSchedule, 
        PayoutExecuted, IFundDispatcher, IFundDispatcherTrait, 
        IBeneficiaryDispatcher, IBeneficiaryDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};
    use core::array::ArrayTrait;
    use core::num::traits::Zero;
    use super::super::shared::{IActorDispatcher, IActorDispatcherTrait, ACTOR_FUNDMANAGER, ACTOR_OWNER};

    #[storage]
    struct Storage {
        schedules: Map<ContractAddress, PayoutSchedule>,  // owner => schedule
        fund_dispatcher: ContractAddress,
        beneficiary_dispatcher: ContractAddress,
        // MVP stripped dependencies
        owner: ContractAddress,
        actor_contract_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ScheduleSet: ScheduleSet,
        PayoutExecuted: PayoutExecuted,
    }

    #[derive(Drop, starknet::Event)]
    struct ScheduleSet {
        #[key]
        owner: ContractAddress,
        interval: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, fund_addr: ContractAddress, ben_addr: ContractAddress, actor_contract: ContractAddress) {
        self.owner.write(owner);
        self.fund_dispatcher.write(fund_addr);
        self.beneficiary_dispatcher.write(ben_addr);
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
    fn get_beneficiary_address(ref self: ContractState) -> ContractAddress { self.beneficiary_dispatcher.read() }

    #[external(v0)]
    fn set_beneficiary_address(ref self: ContractState, new_addr: ContractAddress) {
        assert(get_caller_address() == self.owner.read(), 'Not owner');
        self.beneficiary_dispatcher.write(new_addr);
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
    fn set_schedule(ref self: ContractState, interval: u64) {
        let caller = get_caller_address();
        self.schedules.write(caller, PayoutSchedule { last_payout: get_block_timestamp(), interval, available_funds: 0 });
        self.emit(ScheduleSet { owner: caller, interval });
    }

    #[external(v0)]
    fn execute_payout(ref self: ContractState, owner: ContractAddress) {
        self.restrict_to_payout_caller();
        // Permissionless if due; or owner/automation only
        let mut schedule = self.schedules.read(owner);
        let now = get_block_timestamp();
        assert(now >= schedule.last_payout + schedule.interval, 'Payout not due');

        // Calculate available (placeholder: assume set externally, e.g., from yields)
        let available = schedule.available_funds;  // Or compute from Fund/Investment yields

        let ben_disp = IBeneficiaryDispatcher { contract_address: self.beneficiary_dispatcher.read() };
        let bens = ben_disp.get_beneficiaries(owner);

        let fund_disp = IFundDispatcher { contract_address: self.fund_dispatcher.read() };

        let len = bens.len();
        let mut i: u32 = 0;
        while i < len {
            let ben = bens.at(i);
            // MVP: pay full available equally per call (ignore preferences)
            let share_amount = available;
            let token_amount = share_amount;

        // MVP: Just withdraw the token portion in prefs.token_addr; ignore stables/bitrefill
        if token_amount > 0 {
            let mut f = fund_disp;
            let token_addr: ContractAddress = *ben.prefs.token_addr;
            let dest: ContractAddress = *ben.addr;
            f.withdraw_internal(owner, token_addr, token_amount, dest);
        }

            let dest: ContractAddress = *ben.addr;
            self.emit(PayoutExecuted { owner, beneficiary: dest, amount: share_amount });
            i += 1;
        }

        // Update schedule
        schedule.last_payout = now;
        schedule.available_funds = 0;  // Reset or adjust
        self.schedules.write(owner, schedule);
    }

    // Add view for get_schedule, etc.
    #[external(v0)]
    fn get_schedule(ref self: ContractState, owner: ContractAddress) -> PayoutSchedule {
        self.schedules.read(owner)
    }

    // External setter for available_funds, e.g., from Investment harvest
    #[external(v0)]
    fn set_available_funds(ref self: ContractState, owner: ContractAddress, amount: u256) {
        self.restrict_to_payout_caller();
        let mut schedule = self.schedules.read(owner);
        schedule.available_funds += amount;
        self.schedules.write(owner, schedule);
    }

    // Internal role guard: Owner or Fund Manager
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn restrict_to_payout_caller(self: @ContractState) {
            let caller = get_caller_address();
            if caller == self.owner.read() { return; }
            let actor_disp = IActorDispatcher { contract_address: self.actor_contract_address.read() };
            let actor = actor_disp.get_actor(caller);
            assert(actor.actor_address.is_non_zero(), 'Caller not registered');
            assert(actor.is_active, 'Caller inactive');
            assert(actor.actor_role == ACTOR_FUNDMANAGER || actor.actor_role == ACTOR_OWNER, 'Not allowed');
        }
    }
}