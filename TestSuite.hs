{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad
import System.Exit
import Test.Framework
import Test.Framework.Providers.HUnit
import Test.HUnit

import Network.BitcoinRPC
import Network.BitcoinRPC.EventsTest

auth = RPCAuth "http://127.0.0.1:8332" "rpcuser" "localaccessonly"

test1 = testCase "getblockcount" $ do
    _ <- getBlockCountR Nothing auth
    return ()

test2 = testCase "listreceivedsince" $ do
    _ <- listReceivedSinceR Nothing auth 0
    return ()

test3 = testCase "gettransaction" $ do
    r <- getTransactionR Nothing auth (TransactionID "invalidtransactionid")
    case r of
        Just _ -> assertFailure "invalid transaction id was not rejected"
        Nothing -> return ()

test4 = testCase "getorigins" $ do
    r <- getOriginsR Nothing auth (TransactionID "invalidtransactionid")
    case r of
        Just _ -> assertFailure "invalid transaction id was not rejected"
        Nothing -> return ()

test5 = testCase "getnewaddress" $ do
    _ <- getNewAddressR Nothing auth
    return ()

test6 = testCase "getbalance" $ do
    b1 <- getBalanceR Nothing auth 0
    b2 <- getBalanceR Nothing auth 6
    when (b1 < b2) $
        assertFailure "getbalance reports less unconfirmed funds\
                      \ than confirmed ones (?)"

test7 = testCase "validateaddress" $ do
    c1 <- validateAddressR Nothing auth (BitcoinAddress "invalidaddress")
    when (baiIsValid c1) $
        assertFailure "invalid address is not rejected"
    c2 <-validateAddressR Nothing auth
            (BitcoinAddress "14Z1mazY4HfysZyMaKudFr63EwHqQT2njz")
    when (not (baiIsValid c2)) $
        assertFailure "valid address is rejected"
    myAddr <- getNewAddressR Nothing auth
    c3 <- validateAddressR Nothing auth myAddr
    when (not (baiIsMine c3)) $
        assertFailure "newly created address is not recognized as own"

test8 = testCase "sendtoaddress" $ do
    let nullAmount = BitcoinAmount 0
        largeAmount = BitcoinAmount $ 21000000 * 10 ^ (6::Integer)
    s1 <- sendToAddress auth (BitcoinAddress "invalidaddress") largeAmount
    case s1 of
        Right (Left InvalidAddress) -> return ()
        _ -> assertFailure "invalid address is not rejected"

    myAddr <- getNewAddressR Nothing auth
    s2 <- sendToAddress auth myAddr nullAmount
    case s2 of
        Right (Left InvalidAmount) -> return ()
        _ -> assertFailure "amount of zero is not rejected"

    s3 <- sendToAddress auth myAddr largeAmount
    case s3 of
        Right (Left InsufficientFunds) -> return ()
        _ -> assertFailure "insufficient funds are not detected"

-- TODO: make sure, that (getbalance - getmarkerbalance) can be figured out
--       somehow and then make a sendtoaddress test which sends funds.

main = defaultMain tests

tests = [ test1
        , test2
        , test3
        , test4
        , test5
        , test6
        , test7
        , test8
        ] ++
        eventsTests
