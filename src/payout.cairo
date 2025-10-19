// src/payout_scheduler.cairo

#[starknet::contract]
mod PayoutScheduler {
    use super::super::shared::{PayoutSchedule, Beneficiary, PayoutPrefs, PayoutExecuted, BitrefillEvent, PAYOUT_INTERVAL, IFundDispatcher, IFundDispatcherTrait, IBeneficiaryDispatcher, IBeneficiaryDispatcherTrait, IDEXDispatcher, IDEXDispatcherTrait, INFTDispatcher, INFTDispatcherTrait, IERC20Dispatcher, IERC20DispatcherTrait, SharedEvent};
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use core::array::ArrayTrait;
    use core::serde::Serde;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[storage]
    struct Storage {
        schedules: Map<ContractAddress, PayoutSchedule>,  // owner => schedule
        fund_dispatcher: ContractAddress,
        beneficiary_dispatcher: ContractAddress,
        dex_dispatcher: ContractAddress,                 // e.g., JediSwap or Ekubo
        nft_dispatcher: ContractAddress,                 // For Bitrefill vouchers
        stable_token: ContractAddress,                   // e.g., USDC
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ScheduleSet: ScheduleSet,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        SharedEvent: SharedEvent,
    }

    #[derive(Drop, starknet::Event)]
    struct ScheduleSet {
        #[key]
        owner: ContractAddress,
        interval: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, fund_addr: ContractAddress, ben_addr: ContractAddress, dex_addr: ContractAddress, nft_addr: ContractAddress, stable_addr: ContractAddress) {
        self.ownable.initializer(owner);
        self.fund_dispatcher.write(fund_addr);
        self.beneficiary_dispatcher.write(ben_addr);
        self.dex_dispatcher.write(dex_addr);
        self.nft_dispatcher.write(nft_addr);
        self.stable_token.write(stable_addr);
    }

    #[external(v0)]
    fn set_schedule(ref self: ContractState, interval: u64) {
        let caller = get_caller_address();
        self.schedules.write(caller, PayoutSchedule { last_payout: get_block_timestamp(), interval, available_funds: 0 });
        self.emit(ScheduleSet { owner: caller, interval });
    }

    #[external(v0)]
    fn execute_payout(ref self: ContractState, owner: ContractAddress) {
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
            let share_amount = (available * ben.share.into()) / 100_u256;

            // Split per prefs
            let stable_amount = (share_amount * ben.prefs.stable_pct.into()) / 100_u256;
            let bitrefill_amount = (share_amount * ben.prefs.bitrefill_pct.into()) / 100_u256;
            let token_amount = (share_amount * ben.prefs.token_pct.into()) / 100_u256;

            // Assume base token is e.g., ETH; swap as needed
            let base_token = /* e.g., ETH addr */;

            // Stable: Swap to stable and transfer
            if stable_amount > 0 {
                let dex = IDEXDispatcher { contract_address: self.dex_dispatcher.read() };
                let swapped = dex.swap(base_token, self.stable_token.read(), stable_amount);
                let stable_disp = IERC20Dispatcher { contract_address: self.stable_token.read() };
                stable_disp.transfer(ben.addr, swapped);
            }

            // Token: Direct or swap to prefs.token_addr
            if token_amount > 0 {
                // Similar swap if needed, then transfer
                fund_disp.withdraw_internal(owner, ben.prefs.token_addr, token_amount, ben.addr);
            }

            // Bitrefill: Emit event for relayer to handle API, then mint NFT voucher
            if bitrefill_amount > 0 {
                self.emit(BitrefillEvent { beneficiary: ben.addr, amount: bitrefill_amount, details: "Bitrefill payout request" });
                // Relayer would call back to confirm and mint, but for now assume
                let nft = INFTDispatcher { contract_address: self.nft_dispatcher.read() };
                nft.mint_voucher(ben.addr, bitrefill_amount, "Bitrefill Voucher");
            }

            self.emit(PayoutExecuted { owner, beneficiary: ben.addr, amount: share_amount });
            i += 1;
        }

        // Update schedule
        schedule.last_payout = now;
        schedule.available_funds = 0;  // Reset or adjust
        self.schedules.write(owner, schedule);
    }

    // Add view for get_schedule, etc.
    #[view(v0)]
    fn get_schedule(self: @ContractState, owner: ContractAddress) -> PayoutSchedule {
        self.schedules.read(owner)
    }

    // External setter for available_funds, e.g., from Investment harvest
    #[external(v0)]
    fn set_available_funds(ref self: ContractState, owner: ContractAddress, amount: u256) {
        self.ownable.assert_only_owner();  // Or from Investment contract
        let mut schedule = self.schedules.read(owner);
        schedule.available_funds += amount;
        self.schedules.write(owner, schedule);
    }
}