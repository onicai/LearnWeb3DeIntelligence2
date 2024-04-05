import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Canister "mo:matchers/Canister";
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
    // Info stored about canisters per user
    public type UserCreationEntry = {
        selectedModel : AvailableModels;
        modelCanister : CanisterInfo;
        frontendCanister : ?CanisterInfo;
    };

    public type CanisterType = {
        #Model;
        #Frontend;
    };

    public type CanisterInfo = {
        canisterType : CanisterType;
        creationTimestamp : Nat64;
        canisterAddress : Text;
    };

    public type CanisterConfiguration = {
        canisterType : CanisterType;
        selectedModel : ?AvailableModels;
        owner: ?Principal;
    };

    public type UserCanistersEntryResult = Result<UserCreationEntry, ApiError>;

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

    // data needed to create a new canister with the frontend
    public type FrontendCreationArtefacts = {
        canisterWasm : Blob;
        assetsToUpload : [Blob];
    };

    public type FrontendConfiguration = {
        selectedModel : AvailableModels;
        owner: Principal;
        associatedModelCanisterId : Text;
    };

    public type FrontendCreationRecord = {
        creationResult : Text;
        newCanisterId : Text;
    };

    public type FrontendCreationResult = Result<FrontendCreationRecord, ApiError>;
};
