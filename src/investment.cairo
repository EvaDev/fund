// src/invest.cairo

#[starknet::contract]
mod Investment {
    use super::super::shared::{Allocation, ProtocolType, IOracleDispatcher, IOracleDispatcherTrait, IFundDispatcher, IFundDispatcherTrait, IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::{Map, Vec, StorageMapReadAccess, StorageMapWriteAccess, StorageVecReadAccess, StorageVecWriteAccess};
    use core::array::ArrayTrait;
    use core::serde::Serde;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[storage]
    struct Storage {
        allocations: Map<ContractAddress, Vec<Allocation>>,  // owner => Vec<Allocation>
        fund_dispatcher: ContractAddress,                   // Address of Fund contract
        oracle_dispatcher: ContractAddress,                 // Pragma/Chainlink oracle
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AllocationSet: AllocationSet,
        InvestmentMade: InvestmentMade,
        YieldsHarvested: YieldsHarvested,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
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
    fn constructor(ref self: ContractState, owner: ContractAddress, fund_addr: ContractAddress, oracle_addr: ContractAddress) {
        self.ownable.initializer(owner);
        self.fund_dispatcher.write(fund_addr);
        self.oracle_dispatcher.write(oracle_addr);
    }

    #[external(v0)]
    fn set_allocations(ref self: ContractState, allocs: Array<Allocation>) {
        let caller = get_caller_address();
        let mut total_pct: u8 = 0;
        let mut i: u32 = 0;
        let len = allocs.len();
        while i < len {
            let alloc = allocs.at(i);
            total_pct += alloc.percentage;
            i += 1;
        }
        assert(total_pct == 100, 'Percentages must sum to 100');

        let mut vec_allocs: Vec<Allocation> = Vec::new();
        let mut j: u32 = 0;
        while j < len {
            vec_allocs.append(allocs.at(j));
            j += 1;
        }
        self.allocations.write(caller, vec_allocs);

        self.emit(AllocationSet { owner: caller, allocations_count: len });
    }

    #[external(v0)]
    fn invest(ref self: ContractState) {
        let caller = get_caller_address();
        let allocs = self.allocations.read(caller);
        let fund_addr = self.fund_dispatcher.read();
        let fund = IFundDispatcher { contract_address: fund_addr };

        // Assume single token for simplicity; extend for multi
        let token = /* e.g., USDC addr */;
        let balance = fund.get_balance(caller, token);

        let len = allocs.len();
        let mut i: u32 = 0;
        while i < len {
            let alloc = allocs.at(i);
            let amount = (balance * alloc.percentage.into()) / 100_u256;

            // Approve and call protocol's deposit/supply fn
            let token_disp = IERC20Dispatcher { contract_address: token };
            token_disp.approve(alloc.protocol_addr, amount);

            // Protocol-specific call (use trait or match on type)
            match alloc.protocol_type {
                ProtocolType::Lending(()) => {
                    // Call e.g., zkLend supply
                },
                // Add cases
                _ => {},
            }

            self.emit(InvestmentMade { owner: caller, protocol: alloc.protocol_addr, amount });
            i += 1;
        }
    }

    #[external(v0)]
    fn harvest_yields(ref self: ContractState) {
        // Similar loop over allocs, call harvest/claim on each protocol, transfer back to fund
        // Update total_value via oracle
    }

    #[view(v0)]
    fn get_allocations(self: @ContractState, owner: ContractAddress) -> Array<Allocation> {
        let vec_allocs = self.allocations.read(owner);
        let mut arr: Array<Allocation> = ArrayTrait::new();
        let len = vec_allocs.len();
        let mut i: u32 = 0;
        while i < len {
            arr.append(vec_allocs.at(i));
            i += 1;
        }
        arr
    }
}