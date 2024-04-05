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

import Types "Types";
import Utils "Utils";

actor class AissemblyLineCanister(_model_creation_canister_id : Text, _frontend_creation_canister_id : Text) {

    let MODEL_CREATION_CANISTER_ID : Text = _model_creation_canister_id;

    let modelCreationCanister = actor (MODEL_CREATION_CANISTER_ID) : actor {
        amiController() : async Types.AuthRecordResult;
        createCanister : (configurationInput : Types.ModelConfiguration) -> async Types.ModelCreationResult;
    };

    let FRONTEND_CREATION_CANISTER_ID : Text = _frontend_creation_canister_id;

    let frontendCreationCanister = actor (FRONTEND_CREATION_CANISTER_ID) : actor {
        amiController() : async Types.AuthRecordResult;
        createCanister : (configurationInput : Types.FrontendConfiguration) -> async Types.FrontendCreationResult;
    };

    // -------------------------------------------------------------------------------
    // Orthogonal Persisted Data storage

    // Map each user Principal to a record with the info about the created canisters
    private var creationsByUser = HashMap.HashMap<Principal, Types.UserCreationEntry>(0, Principal.equal, Principal.hash);
    stable var creationsByUserStable : [(Principal, Types.UserCreationEntry)] = [];

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

    // Admin function to verify that donation_tracker_canister is a controller of the donation_canister
    /* public shared (msg) func isControllerLogicOk() : async Types.AuthRecordResult {
        if (not Principal.isController(msg.caller)) {
            return #Err(#Unauthorized);
        };

        // Call donation_canister to verify that donation_tracker_canister is a controller
        try {
            let authRecordResult : Types.AuthRecordResult = await donationCanister.amiController();
            return authRecordResult;
        } catch (error : Error) {
            // Handle errors, such as donation canister not responding
            return #Err(#Other("Failed to retrieve controller info for DONATION_CANISTER_ID = " # DONATION_CANISTER_ID));
        };
    }; */

    // -------------------------------------------------------------------------------
    // Canister upgrades

    // System-provided lifecycle method called before an upgrade.
    system func preupgrade() {
        // Copy the runtime state back into the stable variable before upgrade.
        creationsByUserStable := Iter.toArray(creationsByUser.entries());
    };

    // System-provided lifecycle method called after an upgrade or on initial deploy.
    system func postupgrade() {
        // After upgrade, reload the runtime state from the stable variable.
        creationsByUser := HashMap.fromIter(Iter.fromArray(creationsByUserStable), creationsByUserStable.size(), Principal.equal, Principal.hash);
        creationsByUserStable := [];
    };
    // -------------------------------------------------------------------------------
};
