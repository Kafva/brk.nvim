#!/usr/bin/env runhaskell
import System.Environment (getArgs)
import Control.Monad (when, forM_)
import System.Exit (die)
import Text.Printf (printf)

fib :: Int -> Int
fib k
    | k == 0 = 0
    | k == 1 = 1
    | otherwise = fib (k - 1) + fib (k - 2)


main :: IO ()
main = do
    args <- getArgs
    when (null args) $ die "No arguments provided"
    forM_ args $ \arg -> do
        let num = read arg
        printf "fib(%d) = %d\n" num (fib num)
