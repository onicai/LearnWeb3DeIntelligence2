# Creation Canister

### Setup

Install mops (https://mops.one/docs/install)
Install motoko dependencies:

```bash
mops install
```

### Deploy

We assume you already have the `backend/donation_canister` deployed.

Then you deploy the donation_tracker_canister with:

```bash
# -----------------------
# During deployment, you must pass the DONATION_CANISTER_ID:
# - local     : get the canister id from the donation_canister deployment step
# - ic mainnet: "ekral-oiaaa-aaaag-acmda-cai"
#
# After deployment, you must initialize the Recipients (demo data...)

# local
dfx deploy donation_tracker_canister --argument '("bkyz2-fmaaa-aaaaa-qaaaq-cai")'
dfx canister call donation_tracker_canister initRecipients

# IC mainnet
dfx deploy --ic donation_tracker_canister --argument '("ekral-oiaaa-aaaag-acmda-cai")'
dfx canister --ic call donation_tracker_canister initRecipients

# Generate the bindings for the frontend
dfx generate
```

### Test with dfx

```bash
dfx canister call donation_tracker_canister whoami

# Run with same identity used to deploy (as a controller)
$ dfx canister call donation_tracker_canister amiController
(variant { Ok = record { auth = "You are a controller of this canister." } })

# This call checks if the donation_tracker_canister is a controller of the donation_canister
# -> required for access to the send method
$ dfx canister call donation_tracker_canister isControllerLogicOk
(variant { Ok = record { auth = "You are a controller of this canister." } })
```

### Test with pytest

**Create a conda environment**

```bash
conda create --name 2024SABH python=3.10
conda activate 2024SABH

pip install -r requirements.txt
```

**Run tests**

Run the tests with the same identity that you used to deploy the canister.
Your identity must be a controller for some of the tests:

```bash
# local
pytest

# ic mainnet
pytest --network ic
```