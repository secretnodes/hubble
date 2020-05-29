import Ledger from '@lunie/cosmos-ledger';

export async function LedgerConnector () {
  const signMessage = {} || ``
  const ledger = await Ledger().connect()
  const signature = await ledger.sign(signMessage)
}