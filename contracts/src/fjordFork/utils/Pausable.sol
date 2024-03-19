// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

abstract contract Pausable {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Paused(bool);

    event RedeemOpen(bool);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error EnforcedPause();

    error EnforcedRedeemNotOpen();

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    bool public paused;

    bool public redeemOpen;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier whenNotPaused() {
        if (paused) revert EnforcedPause();
        _;
    }

    modifier whenNotRedeemOpen() {
        if (!redeemOpen) revert EnforcedRedeemNotOpen();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Internal Logic
    /// -----------------------------------------------------------------------

    function _togglePause() internal virtual {
        emit Paused(paused = !paused);
    }

    function _toggleRedeemOpen() internal virtual {
        emit RedeemOpen(redeemOpen = !redeemOpen);
    }
}
