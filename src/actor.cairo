// src/actor.cairo - Minimal actor registry for Fund system

#[starknet::contract]
mod Actor {
    use core::array::ArrayTrait;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::super::shared::{Actor, BeneficiaryProfile, ACTOR_OWNER};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        actors: Map<ContractAddress, Actor>,
        profiles: Map<ContractAddress, BeneficiaryProfile>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ActorUpserted: ActorUpserted,
        ProfileUpserted: ProfileUpserted,
        OwnerRotated: OwnerRotated,
    }

    #[derive(Drop, starknet::Event)]
    struct ActorUpserted { actor_address: ContractAddress, role: felt252 }

    #[derive(Drop, starknet::Event)]
    struct ProfileUpserted { actor_address: ContractAddress }

    #[derive(Drop, starknet::Event)]
    struct OwnerRotated { new_owner: ContractAddress }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        // Optionally seed owner actor record
        let owner_actor = Actor { actor_address: owner, actor_role: ACTOR_OWNER, is_active: true, can_modify_fund: true, actor_name: 'Owner' };
        self.actors.write(owner, owner_actor);
    }

    // Owner admin
    #[external(v0)]
    fn get_owner(ref self: ContractState) -> ContractAddress { self.owner.read() }

    #[external(v0)]
    fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
        assert(get_caller_address() == self.owner.read(), 'Only owner');
        self.owner.write(new_owner);
        self.emit(OwnerRotated { new_owner });
    }

    // Upsert actor core (owner-only)
    #[external(v0)]
    fn upsert_actor(ref self: ContractState, actor: Actor) {
        assert(get_caller_address() == self.owner.read(), 'Only owner');
        self.actors.write(actor.actor_address, actor);
        self.emit(ActorUpserted { actor_address: actor.actor_address, role: actor.actor_role });
    }

    // Upsert profile (actor or owner can set their own profile)
    #[external(v0)]
    fn upsert_beneficiary_profile(ref self: ContractState, profile: BeneficiaryProfile) {
        let caller = get_caller_address();
        assert(caller == profile.beneficiary_address || caller == self.owner.read(), 'Not authorized');
        let addr = profile.beneficiary_address;
        self.profiles.write(addr, profile);
        self.emit(ProfileUpserted { actor_address: addr });
    }

    // Views
    #[external(v0)]
    fn get_actor(ref self: ContractState, actor_address: ContractAddress) -> Actor { self.actors.read(actor_address) }

    #[external(v0)]
    fn get_profile(ref self: ContractState, actor_address: ContractAddress) -> BeneficiaryProfile { self.profiles.read(actor_address) }
}


