"""Test canister APIs

   First deploy the canister, then run:

   $ pytest --network=[local/ic] test_apis.py

"""

# pylint: disable=unused-argument, missing-function-docstring, unused-import, wildcard-import, unused-wildcard-import, line-too-long, invalid-name

from pathlib import Path
import pytest
from icpp.smoketest import call_canister_api

# Path to the dfx.json file
DFX_JSON_PATH = Path(__file__).parent / "../dfx.json"

# Canister in the dfx.json file we want to test
CANISTER_NAME = "donation_tracker_canister"


def test__whoami_anonymous(identity_anonymous: dict[str, str], network: str) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="whoami",
        canister_argument="()",
        network=network,
        timeout_seconds=10,
    )
    expected_response = f'(principal "{identity_anonymous["principal"]}")'
    assert response == expected_response


def test__whoami_default(identity_default: dict[str, str], network: str) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="whoami",
        canister_argument="()",
        network=network,
        timeout_seconds=10,
    )
    expected_response = f'(principal "{identity_default["principal"]}")'
    assert response == expected_response


def test__amiController_anonymous(
    identity_anonymous: dict[str, str], network: str
) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="amiController",
        canister_argument="()",
        network=network,
        timeout_seconds=10,
    )
    expected_response = "(variant { Err = variant { Unauthorized } })"
    assert response == expected_response


def test__amiController(network: str) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="amiController",
        canister_argument="()",
        network=network,
        timeout_seconds=10,
    )
    expected_response = (
        '(variant { Ok = record { auth = "You are a controller of this canister.";} })'
    )
    assert response == expected_response


def test__isControllerLogicOk(network: str) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="isControllerLogicOk",
        canister_argument="()",
        network=network,
        timeout_seconds=10,
    )
    expected_response = (
        '(variant { Ok = record { auth = "You are a controller of this canister.";} })'
    )
    assert response == expected_response


def test__initRecipients_anonymous(
    identity_anonymous: dict[str, str], network: str
) -> None:
    # Only run this test in local network
    if network == "local":
        response = call_canister_api(
            dfx_json_path=DFX_JSON_PATH,
            canister_name=CANISTER_NAME,
            canister_method="initRecipients",
            canister_argument="()",
            network=network,
            timeout_seconds=10,
        )
        expected_response = "(variant { Err = variant { Unauthorized } })"
        assert response == expected_response


def test__initRecipients(network: str) -> None:
    # Only run this test in local network. We do not want to re-initialize the ic
    if network == "local":
        # Initialize the mock schools and students
        response = call_canister_api(
            dfx_json_path=DFX_JSON_PATH,
            canister_name=CANISTER_NAME,
            canister_method="initRecipients",
            canister_argument="()",
            network=network,
            timeout_seconds=10,
        )
        # For now, just check the Mock Data is coming back
        expected_response = "(variant { Ok = opt record { num_students = 4 : nat; num_schools = 2 : nat;} })"
        assert response == expected_response


def test__getRecipient_school(identity_anonymous: dict[str, str], network: str) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="getRecipient",
        canister_argument='(record {recipientId = "school1"})',
        canister_input="idl",
        canister_output="idl",
        network=network,
        timeout_seconds=10,
    )
    # For now, just check the Mock Data is coming back
    expected_response = '(variant { Ok = opt record { recipient = variant { School = record { id = "school1"; thumbnail = "./images/school1_thumbnail.png"; name = "Green Valley High"; address = "123 Green Valley Rd";} };} })'
    assert response == expected_response


def test__getRecipient_student(
    identity_anonymous: dict[str, str], network: str
) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="getRecipient",
        canister_argument='(record {recipientId = "student2School1"})',
        canister_input="idl",
        canister_output="idl",
        network=network,
        timeout_seconds=10,
    )
    # For now, just check the Mock Data is coming back
    expected_response = '(variant { Ok = opt record { recipient = variant { Student = record { id = "student2School1"; thumbnail = "./images/student2School1_thumbnail.png"; name = "Jamie Smith"; schoolId = "school1"; grade = 11 : nat;} };} })'
    assert response == expected_response


def test__getRecipient_not_found(
    identity_anonymous: dict[str, str], network: str
) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="getRecipient",
        canister_argument='(record {recipientId = "non-existent-id"})',
        canister_input="idl",
        canister_output="idl",
        network=network,
        timeout_seconds=10,
    )
    # For now, just check the Mock Data is coming back
    expected_response = '(variant { Err = variant { Other = "Recipient not found." } })'
    assert response == expected_response


def test__listRecipients_schools_all(
    identity_anonymous: dict[str, str], network: str
) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="listRecipients",
        canister_argument='( record {include = "schools"} )',
        network=network,
        timeout_seconds=10,
    )
    # For now, just check the Mock Data is coming back
    expected_response = '(variant { Ok = record { recipients = vec { record { id = "school1"; thumbnail = "./images/school1_thumbnail.png"; name = "Green Valley High";}; record { id = "school2"; thumbnail = "./images/school2_thumbnail.png"; name = "Sunnydale Elementary";};};} })'
    assert response == expected_response


def test__listRecipients_schools_filter(
    identity_anonymous: dict[str, str], network: str
) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="listRecipients",
        canister_argument='( record {include = "studentsForSchool"; recipientIdForSchool = opt "school1"} )',
        canister_input="idl",
        canister_output="idl",
        network=network,
        timeout_seconds=10,
    )
    # For now, just check the Mock Data is coming back
    expected_response = '(variant { Ok = record { recipients = vec { record { id = "student1School1"; thumbnail = "./images/student1School1_thumbnail.png"; name = "Alex Johnson";}; record { id = "student2School1"; thumbnail = "./images/student2School1_thumbnail.png"; name = "Jamie Smith";};};} })'
    assert response == expected_response


def test__getDonationWalletAddress(
    identity_anonymous: dict[str, str], network: str
) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="getDonationWalletAddress",
        canister_argument="(record {paymentType = variant {BTC}})",
        canister_input="idl",
        canister_output="idl",
        network=network,
        timeout_seconds=10,
    )
    # Verify the response
    assert "variant { Ok = record { donationAddress = record { address = " in response
    assert "paymentType = variant { BTC }" in response


def test__getTotalDonationAmount(
    identity_anonymous: dict[str, str], network: str
) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="getTotalDonationAmount",
        canister_argument="(record {paymentType = variant {BTC}})",
        canister_input="idl",
        canister_output="idl",
        network=network,
        timeout_seconds=500,
    )
    # Verify the response
    assert (
        "variant { Ok = record { donationAmount = record { paymentType = variant { BTC }; amount ="
        in response
    )
