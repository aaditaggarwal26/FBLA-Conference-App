import '../models/practice_test_model.dart';
import '../models/question_model.dart';

class PracticeTestsData {
  static List<PracticeTestModel> getAllTests() {
    return [
      ..._getAccountingTests(),
      ..._getAdvancedAccountingTests(),
      ..._getAdvertisingTests(),
      ..._getAgribusinessTests(),
      ..._getBusinessCommunicationTests(),
      ..._getBusinessLawTests(),
      ..._getComputerProblemSolvingTests(),
      ..._getCybersecurityTests(),
      ..._getDataScienceAITests(),
      ..._getEconomicsTests(),
      ..._getHealthcareAdministrationTests(),
      ..._getHumanResourceManagementTests(),
      ..._getInsuranceRiskManagementTests(),
      ..._getIntroductionToBusinessCommunicationTests(),
      ..._getIntroductionToBusinessConceptsTests(),
      ..._getIntroductionToBusinessProceduresTests(),
      ..._getIntroductionToFBLATests(),
      ..._getIntroductionToInformationTechnologyTests(),
      ..._getIntroductionToMarketingConceptsTests(),
      ..._getIntroductionToParliamentaryProcedureTests(),
      ..._getIntroductionToRetailMerchandisingTests(),
      ..._getIntroductionToSupplyChainManagementTests(),
      ..._getJournalismTests(),
      ..._getNetworkingInfrastructuresTests(),
      ..._getOrganizationalLeadershipTests(),
      ..._getPersonalFinanceTests(),
      ..._getProjectManagementTests(),
      ..._getPublicAdministrationManagementTests(),
      ..._getRealEstateTests(),
      ..._getRetailManagementTests(),
      ..._getSecuritiesInvestmentsTests(),
    ];
  }

  static List<PracticeTestModel> getTestsForEvent(String eventName) {
    return getAllTests().where((test) => test.eventName == eventName).toList();
  }

  // Accounting Tests
  static List<PracticeTestModel> _getAccountingTests() {
    return [
      PracticeTestModel(
        id: 'accounting_1',
        title: 'Accounting Fundamentals - Test 1',
        eventName: 'Accounting',
        description: 'Basic accounting principles and financial statements',
        timeLimitMinutes: 30,
        questions: [
          QuestionModel(
            id: 'acc_1_q1',
            question: 'What is the accounting equation?',
            options: [
              'Assets = Liabilities + Equity',
              'Assets = Revenue - Expenses',
              'Liabilities = Assets + Equity',
              'Equity = Assets - Revenue',
            ],
            correctAnswerIndex: 0,
            explanation:
                'The fundamental accounting equation is Assets = Liabilities + Equity. This equation must always balance and forms the foundation of double-entry bookkeeping.',
          ),
          QuestionModel(
            id: 'acc_1_q2',
            question:
                'Which financial statement shows a company\'s financial position at a specific point in time?',
            options: [
              'Income Statement',
              'Balance Sheet',
              'Cash Flow Statement',
              'Statement of Retained Earnings',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The Balance Sheet shows a company\'s assets, liabilities, and equity at a specific point in time, providing a snapshot of the company\'s financial position.',
          ),
          QuestionModel(
            id: 'acc_1_q3',
            question: 'What is a journal entry?',
            options: [
              'A summary of all transactions',
              'A chronological record of transactions',
              'A financial statement',
              'A tax document',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A journal entry is a chronological record of transactions in the accounting system, showing debits and credits for each transaction.',
          ),
          QuestionModel(
            id: 'acc_1_q4',
            question: 'Which account type increases with a debit?',
            options: ['Revenue', 'Expenses', 'Liabilities', 'Equity'],
            correctAnswerIndex: 1,
            explanation:
                'Expenses increase with debits. Assets and expenses have debit balances, while liabilities, equity, and revenue have credit balances.',
          ),
          QuestionModel(
            id: 'acc_1_q5',
            question: 'What is the purpose of the trial balance?',
            options: [
              'To calculate net income',
              'To verify that debits equal credits',
              'To prepare tax returns',
              'To create financial statements',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A trial balance is used to verify that total debits equal total credits, ensuring the accounting records are mathematically correct.',
          ),
          QuestionModel(
            id: 'acc_1_q6',
            question: 'What is accounts payable?',
            options: [
              'Money the company owes to suppliers',
              'Money customers owe the company',
              'Cash in the bank',
              'Revenue earned',
            ],
            correctAnswerIndex: 0,
            explanation:
                'Accounts payable represents money the company owes to suppliers or vendors for goods or services purchased on credit.',
          ),
          QuestionModel(
            id: 'acc_1_q7',
            question: 'What is the income statement also known as?',
            options: [
              'Balance Sheet',
              'Profit and Loss Statement',
              'Cash Flow Statement',
              'Statement of Equity',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The income statement is also called the Profit and Loss (P&L) statement and shows revenues, expenses, and net income over a period.',
          ),
          QuestionModel(
            id: 'acc_1_q8',
            question: 'What is double-entry bookkeeping?',
            options: [
              'Recording transactions once',
              'Recording each transaction with equal debits and credits',
              'Using two journals',
              'Recording only cash transactions',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Double-entry bookkeeping requires that every transaction affects at least two accounts with equal debits and credits, keeping the accounting equation balanced.',
          ),
          QuestionModel(
            id: 'acc_1_q9',
            question: 'What is a ledger?',
            options: [
              'A journal entry',
              'A collection of accounts showing all transactions',
              'A financial statement',
              'A tax document',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A ledger is a collection of accounts that contains all the transactions for each account, organized by account type.',
          ),
          QuestionModel(
            id: 'acc_1_q10',
            question: 'What is the matching principle?',
            options: [
              'Matching colors in reports',
              'Expenses should be matched with revenues in the same period',
              'Matching assets with liabilities',
              'Matching debits with credits',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The matching principle states that expenses should be recognized in the same accounting period as the revenues they help generate.',
          ),
          QuestionModel(
            id: 'acc_1_q11',
            question: 'What is a fiscal year?',
            options: [
              'A calendar year',
              'A 12-month period used for accounting purposes',
              'A 6-month period',
              'A tax year only',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A fiscal year is a 12-month period used by companies for accounting and financial reporting, which may or may not align with the calendar year.',
          ),
          QuestionModel(
            id: 'acc_1_q12',
            question: 'What is inventory?',
            options: [
              'Cash on hand',
              'Goods held for sale or production',
              'Fixed assets',
              'Accounts receivable',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Inventory represents goods that a company holds for sale in the ordinary course of business or for use in production.',
          ),
          QuestionModel(
            id: 'acc_1_q13',
            question: 'What is the difference between cash and accrual accounting?',
            options: [
              'No difference',
              'Cash records when money changes hands, accrual records when earned/incurred',
              'Accrual is only for large companies',
              'Cash is more accurate',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Cash accounting records transactions when cash is received/paid, while accrual accounting records when revenue is earned or expenses are incurred, regardless of cash flow.',
          ),
          QuestionModel(
            id: 'acc_1_q14',
            question: 'What is a prepaid expense?',
            options: [
              'An expense paid in advance',
              'An expense that is overdue',
              'A revenue item',
              'A liability',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A prepaid expense is an asset representing expenses paid in advance, such as prepaid insurance or rent, that will be recognized as expenses in future periods.',
          ),
          QuestionModel(
            id: 'acc_1_q15',
            question: 'What is the chart of accounts?',
            options: [
              'A list of all accounts used by a company',
              'A financial statement',
              'A list of customers',
              'A tax document',
            ],
            correctAnswerIndex: 0,
            explanation:
                'The chart of accounts is a listing of all accounts used by a company, organized by account type (assets, liabilities, equity, revenue, expenses).',
          ),
          QuestionModel(
            id: 'acc_1_q16',
            question: 'What is a contra account?',
            options: [
              'An account that offsets another account',
              'A revenue account',
              'A liability account',
              'An expense account',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A contra account is an account that offsets or reduces the balance of another account, such as Accumulated Depreciation (contra asset) or Allowance for Doubtful Accounts.',
          ),
          QuestionModel(
            id: 'acc_1_q17',
            question: 'What is the going concern principle?',
            options: [
              'A company will continue operating indefinitely',
              'A company is going out of business',
              'A type of expense',
              'A revenue recognition method',
            ],
            correctAnswerIndex: 0,
            explanation:
                'The going concern principle assumes that a company will continue to operate indefinitely, allowing for proper asset valuation and financial reporting.',
          ),
          QuestionModel(
            id: 'acc_1_q18',
            question: 'What is a T-account?',
            options: [
              'A visual representation of an account',
              'A type of financial statement',
              'A tax account',
              'A revenue account',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A T-account is a visual representation of an account showing debits on the left and credits on the right, resembling the letter "T".',
          ),
          QuestionModel(
            id: 'acc_1_q19',
            question: 'What is the cost principle?',
            options: [
              'Assets are recorded at their original cost',
              'All costs must be expensed immediately',
              'Costs equal revenues',
              'A pricing strategy',
            ],
            correctAnswerIndex: 0,
            explanation:
                'The cost principle states that assets should be recorded at their original purchase cost, not their current market value.',
          ),
          QuestionModel(
            id: 'acc_1_q20',
            question: 'What is the revenue recognition principle?',
            options: [
              'Revenue is recognized when cash is received',
              'Revenue is recognized when earned, regardless of cash receipt',
              'Revenue is never recognized',
              'Revenue equals expenses',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The revenue recognition principle states that revenue should be recognized when it is earned and realizable, regardless of when cash is received.',
          ),
        ],
      ),
      PracticeTestModel(
        id: 'accounting_2',
        title: 'Accounting Fundamentals - Test 2',
        eventName: 'Accounting',
        description: 'Journal entries and the accounting cycle',
        timeLimitMinutes: 30,
        questions: [
          QuestionModel(
            id: 'acc_2_q1',
            question: 'What are the steps in the accounting cycle in order?',
            options: [
              'Journal, Ledger, Trial Balance, Financial Statements',
              'Financial Statements, Journal, Ledger, Trial Balance',
              'Trial Balance, Journal, Ledger, Financial Statements',
              'Ledger, Journal, Financial Statements, Trial Balance',
            ],
            correctAnswerIndex: 0,
            explanation:
                'The accounting cycle follows: 1) Record transactions in journal, 2) Post to ledger, 3) Prepare trial balance, 4) Create financial statements.',
          ),
          QuestionModel(
            id: 'acc_2_q2',
            question: 'What is an accrual?',
            options: [
              'A cash payment',
              'Revenue or expense recognized before cash is exchanged',
              'A type of asset',
              'A liability account',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Accruals are revenues or expenses that are recognized in the accounting period they occur, regardless of when cash is received or paid.',
          ),
          QuestionModel(
            id: 'acc_2_q3',
            question:
                'Which account is closed at the end of the accounting period?',
            options: ['Cash', 'Accounts Receivable', 'Revenue', 'Equipment'],
            correctAnswerIndex: 2,
            explanation:
                'Revenue accounts (along with expense accounts) are temporary accounts that are closed to retained earnings at the end of each accounting period.',
          ),
          QuestionModel(
            id: 'acc_2_q4',
            question: 'What is depreciation?',
            options: [
              'An increase in asset value',
              'The allocation of asset cost over its useful life',
              'A type of liability',
              'A revenue account',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Depreciation is the systematic allocation of the cost of a tangible asset over its useful life, matching expenses with revenues.',
          ),
          QuestionModel(
            id: 'acc_2_q5',
            question: 'What does COGS stand for?',
            options: [
              'Cost of Goods Sold',
              'Cost of General Services',
              'Cash on Goods Sold',
              'Credit on Goods Sold',
            ],
            correctAnswerIndex: 0,
            explanation:
                'COGS stands for Cost of Goods Sold, which represents the direct costs attributable to the production of goods sold by a company.',
          ),
          QuestionModel(
            id: 'acc_2_q6',
            question: 'What is the closing process?',
            options: [
              'Closing the business',
              'Transferring temporary account balances to permanent accounts',
              'Closing the accounting period',
              'Closing the ledger',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The closing process transfers balances from temporary accounts (revenue, expense) to permanent accounts (retained earnings) at the end of an accounting period.',
          ),
          QuestionModel(
            id: 'acc_2_q7',
            question: 'What is a post-closing trial balance?',
            options: [
              'A trial balance before closing entries',
              'A trial balance after closing entries, showing only permanent accounts',
              'A financial statement',
              'A tax document',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A post-closing trial balance is prepared after closing entries and contains only permanent accounts (assets, liabilities, equity), verifying the accounting equation still balances.',
          ),
          QuestionModel(
            id: 'acc_2_q8',
            question: 'What is the difference between a debit and a credit?',
            options: [
              'No difference',
              'Debits increase assets/expenses, credits increase liabilities/equity/revenue',
              'Debits are always positive',
              'Credits are always negative',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Debits increase assets and expenses, while credits increase liabilities, equity, and revenue. The accounting equation must always balance.',
          ),
          QuestionModel(
            id: 'acc_2_q9',
            question: 'What is an unearned revenue?',
            options: [
              'Revenue that is overdue',
              'Payment received before services are provided',
              'Revenue that cannot be collected',
              'Revenue from last year',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Unearned revenue is a liability representing payment received before goods or services are delivered, which will become revenue when earned.',
          ),
          QuestionModel(
            id: 'acc_2_q10',
            question: 'What is the difference between a current and non-current asset?',
            options: [
              'No difference',
              'Current assets are expected to be used/sold within one year',
              'Non-current assets are always cash',
              'Current assets are more valuable',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Current assets are expected to be converted to cash or used within one year, while non-current assets are long-term resources used over multiple years.',
          ),
          QuestionModel(
            id: 'acc_2_q11',
            question: 'What is bad debt expense?',
            options: [
              'An expense for uncollectible accounts',
              'A type of revenue',
              'A liability',
              'An asset account',
            ],
            correctAnswerIndex: 0,
            explanation:
                'Bad debt expense represents accounts receivable that are estimated to be uncollectible, recognized as an expense in the period the sale was made.',
          ),
          QuestionModel(
            id: 'acc_2_q12',
            question: 'What is the straight-line method of depreciation?',
            options: [
              'Depreciation that curves',
              'Equal depreciation expense each period',
              'Depreciation only in straight lines',
              'No depreciation',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Straight-line depreciation allocates an equal amount of depreciation expense to each period over the asset\'s useful life.',
          ),
          QuestionModel(
            id: 'acc_2_q13',
            question: 'What is a reversing entry?',
            options: [
              'An entry that reverses a previous entry',
              'An entry made at the beginning of a period to reverse adjusting entries',
              'A correction entry',
              'A closing entry',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Reversing entries are optional entries made at the beginning of an accounting period to reverse certain adjusting entries from the previous period.',
          ),
          QuestionModel(
            id: 'acc_2_q14',
            question: 'What is the difference between a note payable and accounts payable?',
            options: [
              'No difference',
              'Notes payable are formal written promises, accounts payable are informal',
              'Accounts payable are always larger',
              'Notes payable are never paid',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Notes payable are formal written promises to pay with specific terms, while accounts payable are informal obligations from normal business operations.',
          ),
          QuestionModel(
            id: 'acc_2_q15',
            question: 'What is a worksheet in accounting?',
            options: [
              'A spreadsheet for calculations',
              'A working paper used to organize information for financial statements',
              'A tax form',
              'A journal',
            ],
            correctAnswerIndex: 1,
            explanation:
                'An accounting worksheet is a working paper used to organize and summarize information needed to prepare financial statements and adjusting entries.',
          ),
          QuestionModel(
            id: 'acc_2_q16',
            question: 'What is the time period assumption?',
            options: [
              'Time doesn\'t matter',
              'Business activities can be divided into specific time periods',
              'All periods are the same length',
              'Time periods are always one year',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The time period assumption allows businesses to divide their activities into specific time periods (months, quarters, years) for reporting purposes.',
          ),
          QuestionModel(
            id: 'acc_2_q17',
            question: 'What is a compound journal entry?',
            options: [
              'An entry with multiple debits and/or credits',
              'An entry with only one account',
              'A complex entry',
              'A closing entry',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A compound journal entry involves more than two accounts, with multiple debits and/or credits, but total debits must still equal total credits.',
          ),
          QuestionModel(
            id: 'acc_2_q18',
            question: 'What is the difference between FIFO and LIFO?',
            options: [
              'No difference',
              'FIFO uses first-in costs, LIFO uses last-in costs for inventory',
              'FIFO is for assets, LIFO is for liabilities',
              'They are the same method',
            ],
            correctAnswerIndex: 1,
            explanation:
                'FIFO (First-In-First-Out) assumes oldest inventory is sold first, while LIFO (Last-In-First-Out) assumes newest inventory is sold first.',
          ),
          QuestionModel(
            id: 'acc_2_q19',
            question: 'What is a contra revenue account?',
            options: [
              'An account that reduces revenue',
              'A revenue account',
              'An expense account',
              'A liability account',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A contra revenue account reduces gross revenue, such as Sales Returns and Allowances or Sales Discounts.',
          ),
          QuestionModel(
            id: 'acc_2_q20',
            question: 'What is the full disclosure principle?',
            options: [
              'Hide all information',
              'Disclose all relevant information in financial statements',
              'Only disclose positive information',
              'Disclose only to management',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The full disclosure principle requires that all relevant information that could affect users\' understanding of financial statements must be disclosed.',
          ),
        ],
      ),
      PracticeTestModel(
        id: 'accounting_3',
        title: 'Accounting Fundamentals - Test 3',
        eventName: 'Accounting',
        description: 'Financial statements and core concepts',
        timeLimitMinutes: 30,
        questions: [
          QuestionModel(
            id: 'acc_3_q1',
            question: 'What is the formula for net income?',
            options: [
              'Revenue - Expenses',
              'Assets - Liabilities',
              'Revenue + Expenses',
              'Assets + Liabilities',
            ],
            correctAnswerIndex: 0,
            explanation:
                'Net income is calculated as Revenue minus Expenses. This represents the profit or loss for a specific period.',
          ),
          QuestionModel(
            id: 'acc_3_q2',
            question: 'What is accounts receivable?',
            options: [
              'Money owed by the company',
              'Money owed to the company',
              'Cash in the bank',
              'Inventory value',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Accounts receivable represents money owed to the company by customers who have purchased goods or services on credit.',
          ),
          QuestionModel(
            id: 'acc_3_q3',
            question: 'What is the purpose of adjusting entries?',
            options: [
              'To correct errors',
              'To update accounts at the end of the period',
              'To record cash transactions',
              'To close accounts',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Adjusting entries are made at the end of an accounting period to update accounts and ensure revenues and expenses are recorded in the correct period.',
          ),
          QuestionModel(
            id: 'acc_3_q4',
            question: 'What is working capital?',
            options: [
              'Total assets',
              'Current assets minus current liabilities',
              'Total equity',
              'Net income',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Working capital is calculated as Current Assets minus Current Liabilities and represents a company\'s short-term financial health.',
          ),
          QuestionModel(
            id: 'acc_3_q5',
            question: 'What type of account is retained earnings?',
            options: ['Asset', 'Liability', 'Equity', 'Revenue'],
            correctAnswerIndex: 2,
            explanation:
                'Retained earnings is an equity account that represents the cumulative net income retained in the business after dividends are paid.',
          ),
          QuestionModel(
            id: 'acc_3_q6',
            question: 'What is the statement of cash flows?',
            options: [
              'A statement showing only cash transactions',
              'A financial statement showing cash inflows and outflows',
              'A balance sheet',
              'An income statement',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The statement of cash flows shows cash inflows and outflows from operating, investing, and financing activities over a period.',
          ),
          QuestionModel(
            id: 'acc_3_q7',
            question: 'What is the current ratio?',
            options: [
              'Current assets divided by current liabilities',
              'Current liabilities divided by current assets',
              'Total assets divided by total liabilities',
              'Revenue divided by expenses',
            ],
            correctAnswerIndex: 0,
            explanation:
                'The current ratio measures a company\'s ability to pay short-term obligations and is calculated as current assets divided by current liabilities.',
          ),
          QuestionModel(
            id: 'acc_3_q8',
            question: 'What is stockholders\' equity?',
            options: [
              'Assets minus liabilities',
              'Liabilities plus assets',
              'Revenue minus expenses',
              'Cash only',
            ],
            correctAnswerIndex: 0,
            explanation:
                'Stockholders\' equity (or owner\'s equity) represents the residual interest in assets after deducting liabilities, calculated as Assets minus Liabilities.',
          ),
          QuestionModel(
            id: 'acc_3_q9',
            question: 'What is the difference between gross profit and net income?',
            options: [
              'No difference',
              'Gross profit is revenue minus COGS, net income includes all expenses',
              'Net income is always higher',
              'Gross profit includes taxes',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Gross profit is revenue minus cost of goods sold, while net income is revenue minus all expenses (COGS, operating expenses, taxes, etc.).',
          ),
          QuestionModel(
            id: 'acc_3_q10',
            question: 'What is an asset?',
            options: [
              'Something owned that has value',
              'A liability',
              'An expense',
              'Revenue',
            ],
            correctAnswerIndex: 0,
            explanation:
                'An asset is a resource owned or controlled by a company that has economic value and is expected to provide future benefits.',
          ),
          QuestionModel(
            id: 'acc_3_q11',
            question: 'What is a liability?',
            options: [
              'An obligation to pay',
              'An asset',
              'Revenue',
              'An expense',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A liability is an obligation to transfer assets or provide services to another entity in the future, resulting from past transactions.',
          ),
          QuestionModel(
            id: 'acc_3_q12',
            question: 'What is the accounting period?',
            options: [
              'The time covered by financial statements',
              'A single day',
              'Only the current year',
              'A decade',
            ],
            correctAnswerIndex: 0,
            explanation:
                'An accounting period is the time span covered by financial statements, typically a month, quarter, or year.',
          ),
          QuestionModel(
            id: 'acc_3_q13',
            question: 'What is the materiality principle?',
            options: [
              'All information must be disclosed',
              'Only material (significant) items need to be reported',
              'Material items are not important',
              'Only small items matter',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The materiality principle states that only information significant enough to influence decisions needs to be reported or disclosed.',
          ),
          QuestionModel(
            id: 'acc_3_q14',
            question: 'What is the conservatism principle?',
            options: [
              'Be optimistic in reporting',
              'Choose accounting methods that are least likely to overstate assets or income',
              'Always report losses',
              'Never report gains',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The conservatism principle guides accountants to choose methods that are least likely to overstate assets or income when uncertainty exists.',
          ),
          QuestionModel(
            id: 'acc_3_q15',
            question: 'What is a subsidiary ledger?',
            options: [
              'A detailed ledger for a specific account',
              'A main ledger',
              'A financial statement',
              'A journal',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A subsidiary ledger contains detailed information for a specific account, such as accounts receivable or accounts payable, supporting the general ledger.',
          ),
          QuestionModel(
            id: 'acc_3_q16',
            question: 'What is the difference between gross and net?',
            options: [
              'No difference',
              'Gross is before deductions, net is after deductions',
              'Net is always larger',
              'Gross is after deductions',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Gross amounts are before deductions or adjustments, while net amounts are after all deductions, adjustments, or expenses have been subtracted.',
          ),
          QuestionModel(
            id: 'acc_3_q17',
            question: 'What is a petty cash fund?',
            options: [
              'A small amount of cash for minor expenses',
              'A large cash reserve',
              'A bank account',
              'Accounts receivable',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A petty cash fund is a small amount of cash kept on hand for minor, incidental expenses that are impractical to pay by check.',
          ),
          QuestionModel(
            id: 'acc_3_q18',
            question: 'What is the difference between a capital expenditure and a revenue expenditure?',
            options: [
              'No difference',
              'Capital expenditures are for long-term assets, revenue expenditures are for current expenses',
              'Revenue expenditures are always larger',
              'They are the same thing',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Capital expenditures are for long-term assets that provide benefits over multiple periods, while revenue expenditures are for current period expenses.',
          ),
          QuestionModel(
            id: 'acc_3_q19',
            question: 'What is a bank reconciliation?',
            options: [
              'Matching bank statement with company records',
              'Closing a bank account',
              'Opening a new account',
              'A type of loan',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A bank reconciliation is the process of matching the company\'s cash records with the bank statement to identify and resolve discrepancies.',
          ),
          QuestionModel(
            id: 'acc_3_q20',
            question: 'What is the accounting cycle?',
            options: [
              'A one-time process',
              'The sequence of steps in processing accounting information',
              'A type of account',
              'A financial statement',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The accounting cycle is the sequence of steps in processing accounting information from transactions to financial statements, repeated each accounting period.',
          ),
        ],
      ),
    ];
  }

  // Advanced Accounting Tests
  static List<PracticeTestModel> _getAdvancedAccountingTests() {
    return [
      PracticeTestModel(
        id: 'adv_accounting_1',
        title: 'Advanced Accounting - Test 1',
        eventName: 'Advanced Accounting',
        description: 'Corporate accounting and financial analysis',
        timeLimitMinutes: 30,
        questions: [
          QuestionModel(
            id: 'adv_acc_1_q1',
            question:
                'What is the difference between financial accounting and managerial accounting?',
            options: [
              'No difference',
              'Financial is for external users, managerial is for internal',
              'Managerial is for external users, financial is for internal',
              'They use different currencies',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Financial accounting provides information to external stakeholders (investors, creditors), while managerial accounting provides information for internal decision-making.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q2',
            question: 'What is a consolidated financial statement?',
            options: [
              'A statement for one company',
              'Combined statements of parent and subsidiaries',
              'A tax document',
              'A budget statement',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Consolidated financial statements combine the financial results of a parent company and its subsidiaries into a single set of statements.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q3',
            question: 'What does EPS stand for?',
            options: [
              'Earnings Per Share',
              'Expenses Per Share',
              'Equity Per Share',
              'Expenses Per Statement',
            ],
            correctAnswerIndex: 0,
            explanation:
                'EPS (Earnings Per Share) is calculated by dividing net income by the number of outstanding shares, indicating profitability per share.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q4',
            question: 'What is the debt-to-equity ratio used for?',
            options: [
              'Measuring profitability',
              'Assessing financial leverage',
              'Calculating revenue',
              'Determining tax liability',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The debt-to-equity ratio measures a company\'s financial leverage by comparing total debt to total equity, indicating how much debt is used to finance assets.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q5',
            question: 'What is activity-based costing (ABC)?',
            options: [
              'A method to allocate overhead costs',
              'A type of inventory system',
              'A tax calculation method',
              'A revenue recognition method',
            ],
            correctAnswerIndex: 0,
            explanation:
                'Activity-based costing allocates overhead costs to products based on the activities that drive those costs, providing more accurate product costing.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q6',
            question: 'What is a budget variance?',
            options: [
              'The difference between budgeted and actual amounts',
              'A type of expense',
              'A revenue item',
              'An asset account',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A budget variance is the difference between budgeted (planned) amounts and actual results, which can be favorable or unfavorable.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q7',
            question: 'What is the return on investment (ROI)?',
            options: [
              'A measure of profitability relative to investment',
              'A type of asset',
              'A liability',
              'An expense',
            ],
            correctAnswerIndex: 0,
            explanation:
                'ROI measures the profitability of an investment by comparing net income or gain to the cost of the investment, expressed as a percentage.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q8',
            question: 'What is a flexible budget?',
            options: [
              'A budget that adjusts for different activity levels',
              'A fixed budget',
              'A budget that never changes',
              'A type of expense',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A flexible budget adjusts for different levels of activity, allowing for more accurate performance evaluation by comparing actual results to budgeted amounts at the actual activity level.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q9',
            question: 'What is the difference between direct and indirect costs?',
            options: [
              'No difference',
              'Direct costs can be traced to a product, indirect costs cannot',
              'Indirect costs are always higher',
              'They are the same',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Direct costs can be directly traced to a specific product or service, while indirect costs (overhead) cannot be easily traced and must be allocated.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q10',
            question: 'What is a standard cost?',
            options: [
              'A predetermined cost for a product or service',
              'The actual cost',
              'A type of revenue',
              'An expense',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A standard cost is a predetermined cost for materials, labor, or overhead, used for budgeting and performance evaluation.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q11',
            question: 'What is the difference between absorption and variable costing?',
            options: [
              'No difference',
              'Absorption includes fixed overhead, variable does not',
              'Variable is always higher',
              'They are the same method',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Absorption costing includes all manufacturing costs (including fixed overhead) in product cost, while variable costing includes only variable costs.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q12',
            question: 'What is a responsibility center?',
            options: [
              'A department or unit with specific responsibilities',
              'A type of account',
              'A financial statement',
              'A tax center',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A responsibility center is a department or unit within an organization that has specific responsibilities and is accountable for its performance.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q13',
            question: 'What is the difference between fixed and variable costs?',
            options: [
              'No difference',
              'Fixed costs don\'t change with activity, variable costs do',
              'Variable costs are always higher',
              'They are the same',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Fixed costs remain constant regardless of activity level, while variable costs change proportionally with the level of activity or production.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q14',
            question: 'What is a cost driver?',
            options: [
              'A factor that causes costs to change',
              'A type of expense',
              'A revenue item',
              'An asset',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A cost driver is a factor that causes costs to change, such as machine hours, labor hours, or number of setups, used in activity-based costing.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q15',
            question: 'What is the difference between job order and process costing?',
            options: [
              'No difference',
              'Job order is for unique products, process is for identical products',
              'Process is always better',
              'They are the same',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Job order costing is used for unique, custom products, while process costing is used for identical, mass-produced items.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q16',
            question: 'What is a transfer price?',
            options: [
              'The price charged between divisions of the same company',
              'A customer price',
              'A supplier price',
              'A tax price',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A transfer price is the price charged when one division of a company sells goods or services to another division within the same company.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q17',
            question: 'What is the difference between relevant and irrelevant costs?',
            options: [
              'No difference',
              'Relevant costs affect decisions, irrelevant costs do not',
              'Irrelevant costs are always higher',
              'They are the same',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Relevant costs are future costs that differ between alternatives and affect decision-making, while irrelevant costs do not affect the decision.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q18',
            question: 'What is a capital budget?',
            options: [
              'A budget for long-term investments',
              'A daily budget',
              'A revenue budget',
              'An expense budget',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A capital budget is a plan for long-term investments in assets such as equipment, buildings, or technology that will provide benefits over multiple periods.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q19',
            question: 'What is the difference between incremental and sunk costs?',
            options: [
              'No difference',
              'Incremental costs change with decisions, sunk costs are past costs',
              'Sunk costs are always relevant',
              'They are the same',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Incremental costs are additional costs that result from a decision, while sunk costs are past costs that cannot be changed and are irrelevant to future decisions.',
          ),
          QuestionModel(
            id: 'adv_acc_1_q20',
            question: 'What is a performance report?',
            options: [
              'A report comparing actual to budgeted performance',
              'A financial statement',
              'A tax document',
              'A journal entry',
            ],
            correctAnswerIndex: 0,
            explanation:
                'A performance report compares actual results to budgeted or standard amounts, showing variances to help managers identify areas needing attention.',
          ),
        ],
      ),
      PracticeTestModel(
        id: 'adv_accounting_2',
        title: 'Advanced Accounting - Test 2',
        eventName: 'Advanced Accounting',
        description: 'Managerial accounting and cost analysis',
        timeLimitMinutes: 30,
        questions: [
          QuestionModel(
            id: 'adv_acc_2_q1',
            question: 'What is a cost center?',
            options: [
              'A revenue-generating department',
              'A department that incurs costs but doesn\'t generate revenue',
              'A type of asset',
              'A tax category',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A cost center is a department or unit that incurs costs but doesn\'t directly generate revenue, such as HR or IT departments.',
          ),
          QuestionModel(
            id: 'adv_acc_2_q2',
            question: 'What is the break-even point?',
            options: [
              'Maximum profit point',
              'Point where revenue equals total costs',
              'Minimum sales point',
              'Optimal production level',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The break-even point is the sales level where total revenue equals total costs, resulting in zero profit or loss.',
          ),
          QuestionModel(
            id: 'adv_acc_2_q3',
            question: 'What is variance analysis?',
            options: [
              'Comparing actual results to budgeted amounts',
              'Calculating tax variances',
              'Analyzing revenue only',
              'A type of inventory method',
            ],
            correctAnswerIndex: 0,
            explanation:
                'Variance analysis compares actual financial results to budgeted or standard amounts to identify differences and their causes.',
          ),
          QuestionModel(
            id: 'adv_acc_2_q4',
            question: 'What is the contribution margin?',
            options: [
              'Total revenue',
              'Sales revenue minus variable costs',
              'Net income',
              'Fixed costs',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Contribution margin is sales revenue minus variable costs, representing the amount available to cover fixed costs and generate profit.',
          ),
          QuestionModel(
            id: 'adv_acc_2_q5',
            question: 'What is a master budget?',
            options: [
              'A single department budget',
              'A comprehensive budget combining all operational budgets',
              'A tax budget',
              'A cash-only budget',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A master budget is a comprehensive financial plan that combines all individual budgets (sales, production, cash, etc.) into one integrated budget.',
          ),
        ],
      ),
    ];
  }

  // Advertising Tests
  static List<PracticeTestModel> _getAdvertisingTests() {
    return [
      PracticeTestModel(
        id: 'advertising_1',
        title: 'Advertising Principles - Test 1',
        eventName: 'Advertising',
        description: 'Media planning and branding',
        timeLimitMinutes: 30,
        questions: [
          QuestionModel(
            id: 'adv_1_q1',
            question: 'What are the 4 Ps of marketing?',
            options: [
              'Product, Price, Place, Promotion',
              'People, Process, Physical, Promotion',
              'Profit, Price, Place, Product',
              'Planning, Price, Place, Promotion',
            ],
            correctAnswerIndex: 0,
            explanation:
                'The 4 Ps are Product (what you sell), Price (how much it costs), Place (where it\'s sold), and Promotion (how you advertise).',
          ),
          QuestionModel(
            id: 'adv_1_q2',
            question: 'What is a target audience?',
            options: [
              'All consumers',
              'A specific group of consumers a campaign aims to reach',
              'Competitors',
              'Investors',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A target audience is a specific group of consumers with shared characteristics that a marketing campaign is designed to reach and influence.',
          ),
          QuestionModel(
            id: 'adv_1_q3',
            question: 'What is brand positioning?',
            options: [
              'Physical location of stores',
              'How a brand is perceived relative to competitors',
              'Stock price',
              'Employee placement',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Brand positioning is how a brand differentiates itself in the minds of consumers relative to competing brands.',
          ),
          QuestionModel(
            id: 'adv_1_q4',
            question: 'What is reach in advertising?',
            options: [
              'How far an ad travels',
              'The number of unique people exposed to an ad',
              'The frequency of ads',
              'The cost per ad',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Reach is the number of unique people or households exposed to an advertising message at least once during a campaign period.',
          ),
          QuestionModel(
            id: 'adv_1_q5',
            question: 'What is the AIDA model?',
            options: [
              'Attention, Interest, Desire, Action',
              'Analyze, Implement, Develop, Assess',
              'A type of media channel',
              'A pricing strategy',
            ],
            correctAnswerIndex: 0,
            explanation:
                'AIDA stands for Attention (grab attention), Interest (maintain interest), Desire (create desire), and Action (prompt action).',
          ),
        ],
      ),
      PracticeTestModel(
        id: 'advertising_2',
        title: 'Advertising Principles - Test 2',
        eventName: 'Advertising',
        description: 'Consumer behavior and promotional strategies',
        timeLimitMinutes: 30,
        questions: [
          QuestionModel(
            id: 'adv_2_q1',
            question: 'What is market segmentation?',
            options: [
              'Dividing a market into distinct groups',
              'Combining markets',
              'A pricing strategy',
              'A distribution method',
            ],
            correctAnswerIndex: 0,
            explanation:
                'Market segmentation divides a broad market into smaller, more manageable groups of consumers with similar needs, characteristics, or behaviors.',
          ),
          QuestionModel(
            id: 'adv_2_q2',
            question: 'What is a unique selling proposition (USP)?',
            options: [
              'A common feature',
              'A distinctive benefit that sets a product apart',
              'A pricing strategy',
              'A distribution channel',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A USP is a distinctive benefit or feature that differentiates a product or service from competitors and appeals to consumers.',
          ),
          QuestionModel(
            id: 'adv_2_q3',
            question:
                'What is the difference between advertising and public relations?',
            options: [
              'No difference',
              'Advertising is paid, PR is earned media',
              'PR is paid, advertising is free',
              'They target different audiences',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Advertising is paid media where you control the message, while PR is earned media through relationships and news coverage.',
          ),
          QuestionModel(
            id: 'adv_2_q4',
            question: 'What is consumer behavior?',
            options: [
              'How businesses behave',
              'How consumers make purchasing decisions',
              'A type of advertising',
              'A pricing model',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Consumer behavior is the study of how individuals, groups, and organizations select, buy, use, and dispose of goods and services.',
          ),
          QuestionModel(
            id: 'adv_2_q5',
            question: 'What is a call-to-action (CTA)?',
            options: [
              'A phone number in an ad',
              'A prompt for the consumer to take a specific action',
              'A type of media',
              'A pricing strategy',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A CTA is a prompt that encourages the audience to take a specific action, such as "Buy Now" or "Sign Up Today".',
          ),
        ],
      ),
    ];
  }

  // Continue with other events - using generator for the rest
  static List<PracticeTestModel> _getAgribusinessTests() {
    return _generateGenericTests('Agribusiness', 'agribusiness', [
      'Agricultural marketing',
      'Agricultural economics',
      'Supply chain management',
      'Risk management',
    ]);
  }

  static List<PracticeTestModel> _getBusinessCommunicationTests() {
    return _generateGenericTests('Business Communication', 'bus_comm', [
      'Professional writing',
      'Email communication',
      'Presentation skills',
      'Workplace etiquette',
    ]);
  }

  static List<PracticeTestModel> _getBusinessLawTests() {
    return _generateGenericTests('Business Law', 'bus_law', [
      'Contract law',
      'Employment law',
      'Intellectual property',
      'Consumer protection',
    ]);
  }

  static List<PracticeTestModel> _getComputerProblemSolvingTests() {
    return _generateGenericTests('Computer Problem Solving', 'comp_solve', [
      'Troubleshooting',
      'Operating systems',
      'Hardware basics',
      'Network fundamentals',
    ]);
  }

  static List<PracticeTestModel> _getCybersecurityTests() {
    return _generateGenericTests('Cybersecurity', 'cyber', [
      'Threat identification',
      'Security practices',
      'Encryption',
      'Access control',
    ]);
  }

  static List<PracticeTestModel> _getDataScienceAITests() {
    return _generateGenericTests('Data Science & AI', 'data_ai', [
      'Data analysis',
      'Machine learning',
      'Statistical methods',
      'AI applications',
    ]);
  }

  static List<PracticeTestModel> _getEconomicsTests() {
    return _generateGenericTests('Economics', 'econ', [
      'Supply and demand',
      'Market structures',
      'Fiscal policy',
      'Monetary policy',
    ]);
  }

  static List<PracticeTestModel> _getHealthcareAdministrationTests() {
    return _generateGenericTests('Healthcare Administration', 'healthcare', [
      'Medical terminology',
      'Patient records',
      'Healthcare systems',
      'Office procedures',
    ]);
  }

  static List<PracticeTestModel> _getHumanResourceManagementTests() {
    return _generateGenericTests('Human Resource Management', 'hr', [
      'Recruiting and hiring',
      'Training and development',
      'Performance management',
      'Employee relations',
    ]);
  }

  static List<PracticeTestModel> _getInsuranceRiskManagementTests() {
    return _generateGenericTests('Insurance & Risk Management', 'insurance', [
      'Types of insurance',
      'Risk assessment',
      'Coverage options',
      'Risk management strategies',
    ]);
  }

  static List<PracticeTestModel>
  _getIntroductionToBusinessCommunicationTests() {
    return _generateGenericTests(
      'Introduction to Business Communication',
      'intro_comm',
      [
        'Basic workplace writing',
        'Email communication',
        'Professionalism',
        'Digital communication',
      ],
    );
  }

  static List<PracticeTestModel> _getIntroductionToBusinessConceptsTests() {
    return _generateGenericTests(
      'Introduction to Business Concepts',
      'intro_bus',
      [
        'Management basics',
        'Marketing fundamentals',
        'Finance overview',
        'Operations basics',
      ],
    );
  }

  static List<PracticeTestModel> _getIntroductionToBusinessProceduresTests() {
    return _generateGenericTests(
      'Introduction to Business Procedures',
      'intro_proc',
      [
        'Administrative tasks',
        'Business protocols',
        'Office technology',
        'Workplace decision-making',
      ],
    );
  }

  static List<PracticeTestModel> _getIntroductionToFBLATests() {
    return _generateGenericTests('Introduction to FBLA', 'intro_fbla', [
      'FBLA history',
      'FBLA mission',
      'National programs',
      'Leadership structure',
    ]);
  }

  static List<PracticeTestModel>
  _getIntroductionToInformationTechnologyTests() {
    return _generateGenericTests(
      'Introduction to Information Technology',
      'intro_it',
      [
        'Computer hardware',
        'Operating systems',
        'Basic networking',
        'Data management',
      ],
    );
  }

  static List<PracticeTestModel> _getIntroductionToMarketingConceptsTests() {
    return _generateGenericTests(
      'Introduction to Marketing Concepts',
      'intro_marketing',
      [
        'Product, price, place, promotion',
        'Consumer behavior',
        'Marketing strategies',
        'Promotion techniques',
      ],
    );
  }

  static List<PracticeTestModel>
  _getIntroductionToParliamentaryProcedureTests() {
    return _generateGenericTests(
      'Introduction to Parliamentary Procedure',
      'intro_parliament',
      ['Motions', 'Amendments', 'Voting procedures', 'Meeting structure'],
    );
  }

  static List<PracticeTestModel> _getIntroductionToRetailMerchandisingTests() {
    return _generateGenericTests(
      'Introduction to Retail & Merchandising',
      'intro_retail',
      [
        'Store operations',
        'Product placement',
        'Inventory control',
        'Customer experience',
      ],
    );
  }

  static List<PracticeTestModel>
  _getIntroductionToSupplyChainManagementTests() {
    return _generateGenericTests(
      'Introduction to Supply Chain Management',
      'intro_scm',
      ['Logistics', 'Procurement', 'Inventory management', 'Distribution'],
    );
  }

  static List<PracticeTestModel> _getJournalismTests() {
    return _generateGenericTests('Journalism', 'journalism', [
      'News writing',
      'Reporting',
      'Editing',
      'Media ethics',
    ]);
  }

  static List<PracticeTestModel> _getNetworkingInfrastructuresTests() {
    return _generateGenericTests('Networking Infrastructures', 'networking', [
      'Network design',
      'Protocols',
      'Network hardware',
      'Network security',
    ]);
  }

  static List<PracticeTestModel> _getOrganizationalLeadershipTests() {
    return _generateGenericTests('Organizational Leadership', 'leadership', [
      'Leadership styles',
      'Motivation',
      'Team dynamics',
      'Decision-making',
    ]);
  }

  static List<PracticeTestModel> _getPersonalFinanceTests() {
    return _generateGenericTests('Personal Finance', 'personal_finance', [
      'Budgeting',
      'Saving and banking',
      'Credit and loans',
      'Investing basics',
    ]);
  }

  static List<PracticeTestModel> _getProjectManagementTests() {
    return _generateGenericTests('Project Management', 'project_mgmt', [
      'Project planning',
      'Scheduling',
      'Risk management',
      'Team coordination',
    ]);
  }

  static List<PracticeTestModel> _getPublicAdministrationManagementTests() {
    return _generateGenericTests(
      'Public Administration & Management',
      'public_admin',
      [
        'Public organizations',
        'Government budgeting',
        'Public policy',
        'Political systems',
      ],
    );
  }

  static List<PracticeTestModel> _getRealEstateTests() {
    return _generateGenericTests('Real Estate', 'real_estate', [
      'Property law',
      'Real estate financing',
      'Market analysis',
      'Sales processes',
    ]);
  }

  static List<PracticeTestModel> _getRetailManagementTests() {
    return _generateGenericTests('Retail Management', 'retail_mgmt', [
      'Inventory management',
      'Merchandising',
      'Pricing strategies',
      'Store operations',
    ]);
  }

  static List<PracticeTestModel> _getSecuritiesInvestmentsTests() {
    return _generateGenericTests('Securities & Investments', 'securities', [
      'Stocks and bonds',
      'Mutual funds',
      'Risk vs. return',
      'Portfolio management',
    ]);
  }

  // Helper function to generate generic tests for events
  static List<PracticeTestModel> _generateGenericTests(
    String eventName,
    String prefix,
    List<String> topics,
  ) {
    return List.generate(3, (testIndex) {
      return PracticeTestModel(
        id: '${prefix}_${testIndex + 1}',
        title: '$eventName - Test ${testIndex + 1}',
        eventName: eventName,
        description: 'Practice test covering ${topics.join(", ")}',
        timeLimitMinutes: 30,
        questions: List.generate(20, (qIndex) {
          final topic = topics[qIndex % topics.length];
          return QuestionModel(
            id: '${prefix}_${testIndex + 1}_q${qIndex + 1}',
            question: 'What is a key concept related to $topic in $eventName?',
            options: [
              'Option A: A fundamental principle',
              'Option B: An advanced technique',
              'Option C: A basic method',
              'Option D: A standard practice',
            ],
            correctAnswerIndex: 0,
            explanation:
                'This question covers important concepts in $topic. Understanding these fundamentals is essential for success in $eventName.',
          );
        }),
      );
    });
  }
}
