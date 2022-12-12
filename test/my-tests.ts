import { expect } from "chai";
// hre = hardhat runtime environment & network helper
import hre, { ethers } from "hardhat";
import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { Contract } from "ethers";

describe("Lock", function () {
    async function deployOneYearLockFixture() {
        let lockedAmount = 1_000_000_000; // in wei
        // ... deploy the contract as before ...
        const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
        // time.latest: last mined block
        const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

        // deploy a lock contract where funds can be withdrawn after 1 year
        const Lock = await hre.ethers.getContractFactory("Lock");
        const lock = await Lock.deploy(unlockTime, { value: lockedAmount });
        return { lock, unlockTime, lockedAmount };
    }
    it("Should set the right unlockTime", async function () {
        const { lock, unlockTime } = await loadFixture(
            deployOneYearLockFixture
        );
        expect(await lock.unlockTime()).to.equal(unlockTime);
    });
    it("Should revert with the right error if called too soon", async function () {
        const { lock } = await loadFixture(deployOneYearLockFixture);
        await expect(lock.withdraw()).to.be.revertedWith(
            "You can't withdraw yet"
        );
    });
    it("Should transfer the funds to the owner", async function () {
        const { unlockTime, lock } = await loadFixture(
            deployOneYearLockFixture
        );
        await time.increase(unlockTime);
        await lock.withdraw();
    });
    it("Should revert with the right error if called from another account", async function () {
        const { lock, unlockTime } = await loadFixture(
            deployOneYearLockFixture
        );
        const [owner, otherAccount] = await ethers.getSigners();
        await time.increaseTo(unlockTime);
        await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
            "You aren't the owner"
        );
    });
});
