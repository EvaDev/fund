#[starknet::contract]
mod Beneficiary {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};

    use crate::shared::{Beneficiary, PayoutPrefs, BeneficiaryAdded, InheritanceTriggered, 
        IFundDispatcher, IFundDispatcherTrait};

    #[storage]
    struct Storage {
        beneficiaries: Map<(ContractAddress, u32), Beneficiary>,  // (owner, index) => Beneficiary
        beneficiary_count: Map<ContractAddress, u32>,  // owner => count
        last_ping: Map<ContractAddress, u64>,  // owner => timestamp
        ping_interval: u64,  // e.g., 30 days in seconds
        fund_contract: ContractAddress,  // Fund contract address
        actor_contract_address: ContractAddress,  // ActorRegistry
        contract_owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BeneficiaryAdded: BeneficiaryAdded,
        InheritanceTriggered: InheritanceTriggered,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, _ping_interval: u64, fund_contract: ContractAddress, actor_contract: ContractAddress) {
        self.contract_owner.write(owner);
        self.ping_interval.write(2592000);
        self.fund_contract.write(fund_contract);
        self.actor_contract_address.write(actor_contract);
    }

    // Views / admin for cross-contract addresses
    #[external(v0)]
    fn get_fund_address(ref self: ContractState) -> ContractAddress {
        self.fund_contract.read()
    }

    // Allow rotation by the current fund only (old fund must call to rotate)
    #[external(v0)]
    fn set_fund_address(ref self: ContractState, new_addr: ContractAddress) {
        let caller = get_caller_address();
        assert(caller == self.contract_owner.read(), 'Only owner');
        self.fund_contract.write(new_addr);
    }

    #[external(v0)]
    fn get_owner(ref self: ContractState) -> ContractAddress { self.contract_owner.read() }

    #[external(v0)]
    fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
        assert(get_caller_address() == self.contract_owner.read(), 'Only owner');
        self.contract_owner.write(new_owner);
    }

    // ActorRegistry wiring
    #[external(v0)]
    fn get_actor_contract_address(ref self: ContractState) -> ContractAddress { self.actor_contract_address.read() }

    #[external(v0)]
    fn set_actor_contract_address(ref self: ContractState, new_addr: ContractAddress) {
        assert(get_caller_address() == self.contract_owner.read(), 'Only owner');
        self.actor_contract_address.write(new_addr);
    }

    #[external(v0)]
    fn add_beneficiary(ref self: ContractState, addr: ContractAddress, share: u8, prefs: PayoutPrefs) {
        let caller = get_caller_address();
        let count = self.beneficiary_count.read(caller);
        
        // Validate shares sum <=100, prefs sum=100
        let mut total_share = 0;
        let mut i = 0;
        while i < count {
            let ben = self.beneficiaries.read((caller, i));
            total_share += ben.share;
            i += 1;
        }
        assert(total_share + share <= 100, 'Shares exceed 100');
        assert(prefs.stable_pct + prefs.bitrefill_pct + prefs.token_pct == 100, 'Prefs not 100');

        self.beneficiaries.write((caller, count), Beneficiary { addr, share, prefs });
        self.beneficiary_count.write(caller, count + 1);

        self.emit(BeneficiaryAdded { owner: caller, beneficiary_addr: addr });
    }

    #[external(v0)]
    fn ping(ref self: ContractState) {
        let caller = get_caller_address();
        self.last_ping.write(caller, get_block_timestamp());
    }

    #[external(v0)]
    fn trigger_claim(ref self: ContractState, owner: ContractAddress) {
        let caller = get_caller_address();
        let last = self.last_ping.read(owner);
        assert(get_block_timestamp() > last + self.ping_interval.read(), 'Not overdue');

        // Find if caller is beneficiary
        let count = self.beneficiary_count.read(owner);
        let mut found = false;
        let mut ben: Beneficiary = Beneficiary { 
            addr: caller, 
            share: 0, 
            prefs: PayoutPrefs { 
                stable_pct: 0, 
                bitrefill_pct: 0, 
                token_pct: 0, 
                token_addr: caller 
            } 
        };
        let mut i = 0;
        while i < count {
            let current_ben = self.beneficiaries.read((owner, i));
            if current_ben.addr == caller {
                found = true;
                ben = current_ben;
                break;
            }
            i += 1;
        }
        assert(found, 'Not a beneficiary');

        // Claim logic: Interact with Fund to transfer share
        let fund_contract = self.fund_contract.read();
        let fund_dispatcher = IFundDispatcher { contract_address: fund_contract };
        
        // Get fund data to calculate total value and token balances
        let fund_data = fund_dispatcher.get_fund_data(owner);
        
        // Calculate beneficiary's share amount (uses ben.share)
        let _share_amount = (fund_data.total_value * ben.share.into()) / 100;
        
        // For now, we'll transfer a proportional amount of each token
        // In a full implementation, you would:
        // 1. Get all whitelisted tokens from the fund
        // 2. Calculate share for each token
        // 3. Handle conversion based on payout preferences
        // 4. Transfer tokens to beneficiary
        
        // Placeholder: Transfer a small amount of each token type
        // This would need to be expanded to handle all whitelisted tokens
        // and implement the conversion logic based on PayoutPrefs
        
        // Example: If beneficiary prefers stablecoins, convert other tokens to USDC
        // If they prefer ETH, convert other tokens to ETH, etc.
        
        // For MVP: call fund to transfer proportional shares across all tokens
        let mut fdisp = fund_dispatcher;
        fdisp.transfer_beneficiary_share(owner, caller, ben.share);
        
        self.emit(InheritanceTriggered { owner, beneficiary_addr: caller });
    }
}