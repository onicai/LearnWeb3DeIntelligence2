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

    // Admin function to verify that this canister is a controller of model_creation_canister and frontend_creation_canister
    public shared (msg) func isControllerLogicOk() : async Types.AuthRecordResult {
        if (not Principal.isController(msg.caller)) {
            return #Err(#Unauthorized);
        };
        // Call model_creation_canister to verify that this canister is a controller
        try {
            let authRecordResultModelCanister : Types.AuthRecordResult = await modelCreationCanister.amiController();
            switch (authRecordResultModelCanister) {
                case (#Err(authErrorModelCanister)) { return authRecordResultModelCanister; };
                case (#Ok(authSuccessModelCanister)) {
                    // Call frontend_creation_canister to verify that this canister is a controller
                    let authRecordResultFrontendCanister : Types.AuthRecordResult = await frontendCreationCanister.amiController();
                    return authRecordResultFrontendCanister;
                };
            };
        } catch (error : Error) {
            // Handle any other errors
            return #Err(#Other("Failed to retrieve controller info"));
        };
    };

    private func verifyUserRequest(user : Principal, canisterType : Types.CanisterType) : Bool {
        switch(canisterType) {
            case (#Model) {
                // Verify that the user hasn't created any canisters yet (only one canister pair per user is allowed)
                switch(creationsByUser.get(user)) {
                    case (?existingUserEntry) { return false; }; // only one entry per user
                    case _ { return true; }; // no entry yet
                };
            };
            case (#Frontend) {
                // Verify that the user hasn't created a frontend canister yet (only one canister pair per user is allowed)
                switch(creationsByUser.get(user)) {
                    case (?existingUserEntry) {
                        switch(existingUserEntry.frontendCanister) {
                            case (?existingFrontendCanister) {
                                return false; // only one frontend canister per user
                            };
                            case _ { return true; }; // no frontend canister for this user yet
                        };
                    };
                    case _ { return false; }; // Create model canister first
                };
            };
            case _ { return false; }; // Invalid request
        };
    };

    private func getCanisterInfo(user : Principal, canisterType : Types.CanisterType) : ?Types.CanisterInfo {
        switch(canisterType) {
            case (#Model) {
                switch(creationsByUser.get(user)) {
                    case (?existingUserEntry) { return ?existingUserEntry.modelCanister; };
                    case _ { return null; }; // no entry yet
                };
            };
            case (#Frontend) {
                switch(creationsByUser.get(user)) {
                    case (?existingUserEntry) { return existingUserEntry.frontendCanister; };
                    case _ { return null; }; // no entry yet
                };
            };
            case _ { return null; }; // Invalid request
        };
    };

    public shared (msg) func createNewCanister(configurationInput : Types.CanisterConfiguration) : async Types.ModelCreationResult {
        if (Principal.isAnonymous(msg.caller)) {
            return #Err(#Unauthorized);
        };

        let defaultSelectedModel = #Llama2_15M;

        switch(configurationInput.canisterType) {
            case (#Model) {
                // Verify that the user hasn't created any canisters yet (only one canister pair per user is allowed)
                let verifyUserRequestResult = verifyUserRequest(msg.caller, #Model);
                if (not verifyUserRequestResult) {
                    return #Err(#Unauthorized);
                };
                let modelCanisterConfiguration : Types.ModelConfiguration = {
                    selectedModel : Types.AvailableModels = defaultSelectedModel;
                    owner: Principal = msg.caller;
                };
                let createCanisterResult : Types.ModelCreationResult = await modelCreationCanister.createCanister(modelCanisterConfiguration);
                switch (createCanisterResult) {
                    case (#Err(createCanisterError)) { return createCanisterResult; };
                    case (#Ok(createCanisterSuccess)) {
                        // Create new entry for user
                        let modelCanisterInfo : Types.CanisterInfo = {
                            canisterType : Types.CanisterType = #Model;
                            creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
                            canisterAddress : Text = createCanisterSuccess.newCanisterId;
                        };
                        let userEntry : Types.UserCreationEntry = {
                            selectedModel : Types.AvailableModels = defaultSelectedModel;
                            modelCanister : Types.CanisterInfo = modelCanisterInfo;
                            frontendCanister : ?Types.CanisterInfo = null;
                        };
                        creationsByUser.put(msg.caller, userEntry);
                        return createCanisterResult;
                    };
                };
            };
            case (#Frontend) {
                // Verify that the user hasn't created a frontend canister yet (only one canister pair per user is allowed)
                let verifyUserRequestResult = verifyUserRequest(msg.caller, #Frontend);
                if (not verifyUserRequestResult) {
                    return #Err(#Unauthorized);
                };
                let userModelCanisterInfoResult : ?Types.CanisterInfo = getCanisterInfo(msg.caller, #Model);
                switch(userModelCanisterInfoResult) {
                    case (?userModelCanisterInfo) {
                        let frontendCanisterConfiguration : Types.FrontendConfiguration = {
                            selectedModel : Types.AvailableModels = defaultSelectedModel;
                            owner: Principal = msg.caller;
                            associatedModelCanisterId : Text = userModelCanisterInfo.canisterAddress;
                        };
                        let createCanisterResult : Types.FrontendCreationResult = await frontendCreationCanister.createCanister(frontendCanisterConfiguration);
                        switch (createCanisterResult) {
                            case (#Err(createCanisterError)) { return createCanisterResult; };
                            case (#Ok(createCanisterSuccess)) {
                                // Update entry for user
                                switch(creationsByUser.get(msg.caller)) {
                                    case (?existingUserEntry) {
                                        // update the user's existing entry with the frontend info
                                        let frontendCanisterInfo : Types.CanisterInfo = {
                                            canisterType : Types.CanisterType = #Frontend;
                                            creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
                                            canisterAddress : Text = createCanisterSuccess.newCanisterId;
                                        };
                                        let updatedUserEntry : Types.UserCreationEntry = {
                                            selectedModel : Types.AvailableModels = existingUserEntry.selectedModel;
                                            modelCanister : Types.CanisterInfo = existingUserEntry.modelCanister;
                                            frontendCanister : ?Types.CanisterInfo = ?frontendCanisterInfo;
                                        };
                                        creationsByUser.put(msg.caller, updatedUserEntry);
                                        return createCanisterResult;
                                    };
                                    case _ { return #Err(#Unauthorized); }; // no entry yet but it must exist already
                                };
                            };
                        };
                    };
                    case _ { return #Err(#Unauthorized); }; // no entry yet
                };
            };
            case _ { return #Err(#Unauthorized); };
        };        
    };

    public shared (msg) func getUserCanistersEntry() : async Types.UserCanistersEntryResult {
        if (Principal.isAnonymous(msg.caller)) {
            return #Err(#Unauthorized);
        };

        switch(creationsByUser.get(msg.caller)) {
            case (?existingUserEntry) {
                return #Ok(existingUserEntry);
            };
            case _ { return #Err(#InvalidId); }; // no entry yet
        };
    };


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
