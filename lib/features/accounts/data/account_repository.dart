import '../../../../core/database/database_helper.dart';
import '../domain/account_model.dart';
import '../../transactions/domain/transaction_model.dart';

class AccountRepository {
  final DatabaseHelper _dbHelper;

  AccountRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Account>> getAllAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );

    // Fetch all transactions to compute real-time balances
    final txMaps = await db.query('transactions');
    final transactions = txMaps.map((m) => Transaction.fromMap(m)).toList();

    return maps.map((map) {
      final acc = Account.fromMap(map);
      final balance = _calculateBalance(acc, transactions);
      return acc.copyWith(currentBalanceMinor: balance);
    }).toList();
  }

  int _calculateBalance(Account account, List<Transaction> transactions) {
    int balance = account.openingBalanceMinor;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income && tx.accountId == account.id) {
        balance += tx.amountMinor;
      } else if (tx.type == TransactionType.expense && tx.accountId == account.id) {
        // Credit card or loan liabilities increase with expense, assets decrease
        if (account.isLiability) {
          balance += tx.amountMinor; // Balance represents outstanding debt
        } else {
          balance -= tx.amountMinor;
        }
      } else if (tx.type == TransactionType.transfer) {
        if (tx.accountId == account.id) {
          // Money transferred OUT of this account
          if (account.isLiability) {
            balance += tx.amountMinor;
          } else {
            balance -= tx.amountMinor;
          }
        }
        if (tx.toAccountId == account.id) {
          // Money transferred INTO this account (e.g. paying credit card bill)
          if (account.isLiability) {
            balance -= tx.amountMinor; // Paying CC reduces debt
          } else {
            balance += tx.amountMinor;
          }
        }
      }
    }
    return balance;
  }

  Future<void> createAccount(Account account) async {
    final db = await _dbHelper.database;
    await db.insert('accounts', account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    final db = await _dbHelper.database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
