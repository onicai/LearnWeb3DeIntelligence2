import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
module Types {
    //-------------------------------------------------------------------------
    public type ApiError = {
        #Unauthorized;
        #InvalidId;
        #ZeroAddress;
        #Other : Text;
    };

    public type Result<S, E> = {
        #Ok : S;
        #Err : E;
    };

    //-------------------------------------------------------------------------
    public type AuthRecord = {
        auth : Text;
    };

    public type AuthRecordResult = Result<AuthRecord, ApiError>;

    //-------------------------------------------------------------------------
    // data needed to create a new canister with the model
    public type ModelCreationArtefacts = {
        canisterWasm : Blob;
        modelWeights : Blob;
        tokenizer : Blob;
    };

    public type AvailableModels = {
        #Llama2_15M;
    };

    public type ModelConfiguration = {
        selectedModel : AvailableModels;
        owner: Principal;
    };

    public type ModelCreationRecord = {
        creationResult : Text;
        newCanisterId : Text;
    };

    public type ModelCreationResult = Result<ModelCreationRecord, ApiError>;

// IC Management Canister types
    public type canister_id = Principal;
    public type canister_settings = {
        controllers : ?[Principal];
        freezing_threshold : ?Nat;
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };
    public type definite_canister_settings = {
        controllers : ?[Principal];
        freezing_threshold : Nat;
        memory_allocation : Nat;
        compute_allocation : Nat;
    };
    public type user_id = Principal;
    public type wasm_module = Blob;
    public type canister_status_response = {
        status : { #stopped; #stopping; #running };
        memory_size : Nat;
        cycles : Nat;
        settings : definite_canister_settings;
        module_hash : ?Blob;
    };

    public type IC_Management = actor {
        canister_status : shared query { canister_id : canister_id } -> async canister_status_response;
        create_canister : shared { settings : ?canister_settings } -> async {
            canister_id : canister_id;
        };
        delete_canister : shared { canister_id : canister_id } -> async ();
        deposit_cycles : shared { canister_id : canister_id } -> async ();
        install_code : shared {
            arg : Blob;
            wasm_module : wasm_module;
            mode : { #reinstall; #upgrade; #install };
            canister_id : canister_id;
        } -> async ();
        provisional_create_canister_with_cycles : shared {
            settings : ?canister_settings;
            amount : ?Nat;
        } -> async { canister_id : canister_id };
        provisional_top_up_canister : shared {
            canister_id : canister_id;
            amount : Nat;
        } -> async ();
        raw_rand : shared () -> async Blob;
        start_canister : shared { canister_id : canister_id } -> async ();
        stop_canister : shared { canister_id : canister_id } -> async ();
        uninstall_code : shared { canister_id : canister_id } -> async ();
        update_settings : shared {
            canister_id : Principal;
            settings : canister_settings;
        } -> async ();
    };
};
