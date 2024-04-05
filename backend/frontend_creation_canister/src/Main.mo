import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";
import Int "mo:base/Int";
import List "mo:base/List";
import Bool "mo:base/Bool";
import Cycles "mo:base/ExperimentalCycles";

import Types "Types";
import Utils "Utils";

actor class CreationCanister(_master_canister_id : Text) = this {

    let MASTER_CANISTER_ID : Text = _master_canister_id;

    // -------------------------------------------------------------------------------
    // Orthogonal Persisted Data storage

    // Map each AI model id to a record with the artefacts needed to create a new canister
    private var creationArtefactsByModel = HashMap.HashMap<Text, Types.FrontendCreationArtefacts>(0, Text.equal, Text.hash);
    stable var creationArtefactsByModelStable : [(Text, Types.FrontendCreationArtefacts)] = [];

    // -------------------------------------------------------------------------------
    // Canister Endpoints

    public shared (msg) func whoami() : async Principal {
        return msg.caller;
    };

    public shared (msg) func amiController() : async Types.AuthRecordResult {
        if (not Principal.isController(msg.caller)) {
            return #Err(#Unauthorized);
        };
        let authRecord = { auth = "You are a controller of this canister." };
        return #Ok(authRecord);
    };

    let IC0 : Types.IC_Management = actor ("aaaaa-aa");
    private stable var asset_canister_wasm : Blob = "\de\ad\be\ef"; // TODO

    private func getModelCreationArtefacts(selectedModel : Types.AvailableModels) : ?Types.FrontendCreationArtefacts {
        switch(selectedModel) {
            case (#Llama2_15M) {
                let creationArtefacts : ?Types.FrontendCreationArtefacts = creationArtefactsByModel.get("Llama2_15M"); // TODO
                return creationArtefacts;
            };
            case _ { return null; };
        };
        
    };

// Spin up a new canister with a frontend as specified by the input parameters to interact with the AI model canister
    public shared (msg) func createCanister(configurationInput : Types.FrontendConfiguration) : async Types.FrontendCreationResult {
        // Only backend canister may call this
        if (not Principal.isController(msg.caller)) {
            return #Err(#Unauthorized);
        };
        
        switch(getModelCreationArtefacts(configurationInput.selectedModel)) {
            case (?creationArtefacts) {
                Cycles.add(300_000_000_000);
                
                let create_canister = await IC0.create_canister({
                    settings = ?{
                        freezing_threshold = null;
                        controllers = ?[Principal.fromActor(this), configurationInput.owner];
                        memory_allocation = null;
                        compute_allocation = null;
                    }
                });

                let install_wasm = await IC0.install_code({
                    arg = ""; // TODO
                    wasm_module = creationArtefacts.canisterWasm;
                    mode = #install;
                    canister_id = create_canister.canister_id;
                });

                // TODO: upload assets


                // TODO: set associated model canister address (for new frontend to call)


                let creationRecord = {
                    creationResult = "Success";
                    newCanisterId = Principal.toText(create_canister.canister_id);
                };
                return #Ok(creationRecord);
            };
            case _ { return #Err(#InvalidId); };
        };
    };

    // -------------------------------------------------------------------------------
    // Canister upgrades

    // System-provided lifecycle method called before an upgrade.
    system func preupgrade() {
        // Copy the runtime state back into the stable variable before upgrade.
        creationArtefactsByModelStable := Iter.toArray(creationArtefactsByModel.entries());
    };

    // System-provided lifecycle method called after an upgrade or on initial deploy.
    system func postupgrade() {
        // After upgrade, reload the runtime state from the stable variable.
        creationArtefactsByModel := HashMap.fromIter(Iter.fromArray(creationArtefactsByModelStable), creationArtefactsByModelStable.size(), Text.equal, Text.hash);
        creationArtefactsByModelStable := [];
    };
    // -------------------------------------------------------------------------------
};
