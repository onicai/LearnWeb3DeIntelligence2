import Blob "mo:base/Blob";
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
};
