class Quotes {
  /// Returns a deterministic quote based on the current date.
  /// Same date always returns the same quote.
  static Map<String, String> ofTheDay() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;
    return all[dayOfYear % all.length];
  }

  /// All curated quotes — practical wisdom only.
  static final List<Map<String, String>> all = [
    // ── James Clear ──────────────────────────────────────────────────────
    {
      'quote': 'Every action you take is a vote for the type of person you wish to become.',
      'author': 'James Clear',
    },
    {
      'quote': 'You do not rise to the level of your goals. You fall to the level of your systems.',
      'author': 'James Clear',
    },
    {
      'quote': 'Habits are the compound interest of self-improvement.',
      'author': 'James Clear',
    },
    {
      'quote': 'The task of breaking a bad habit is like uprooting a powerful oak within us.',
      'author': 'James Clear',
    },
    {
      'quote': 'Be the designer of your world and not merely the consumer of it.',
      'author': 'James Clear',
    },
    {
      'quote': 'Missing once is an accident. Missing twice is the start of a new habit.',
      'author': 'James Clear',
    },
    {
      'quote': 'The most effective way to change your habits is to focus not on what you want to achieve, but on who you wish to become.',
      'author': 'James Clear',
    },
    {
      'quote': 'When you fall in love with the process rather than the product, you don\'t have to wait to give yourself permission to be happy.',
      'author': 'James Clear',
    },
    {
      'quote': 'You should be far more concerned with your current trajectory than with your current results.',
      'author': 'James Clear',
    },
    {
      'quote': 'The difference between a good day and a bad day is often a few productive hours.',
      'author': 'James Clear',
    },

    // ── Naval Ravikant ───────────────────────────────────────────────────
    {
      'quote': 'Seek wealth, not money or status. Wealth is having assets that earn while you sleep.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'Learn to sell. Learn to build. If you can do both, you will be unstoppable.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'A fit body, a calm mind, a house full of love. These things cannot be bought — they must be earned.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'The most important trick to be happy is to realize that happiness is a skill that you develop and a choice that you make.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'If you can\'t decide, the answer is no.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'Play long-term games with long-term people.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'Read what you love until you love to read.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'Desire is a contract you make with yourself to be unhappy until you get what you want.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'Specific knowledge is found by pursuing your genuine curiosity and passion rather than whatever is hot right now.',
      'author': 'Naval Ravikant',
    },
    {
      'quote': 'All the real benefits in life come from compound interest.',
      'author': 'Naval Ravikant',
    },

    // ── Warren Buffett ───────────────────────────────────────────────────
    {
      'quote': 'The most important investment you can make is in yourself.',
      'author': 'Warren Buffett',
    },
    {
      'quote': 'Price is what you pay. Value is what you get.',
      'author': 'Warren Buffett',
    },
    {
      'quote': 'Do not save what is left after spending, but spend what is left after saving.',
      'author': 'Warren Buffett',
    },
    {
      'quote': 'It takes 20 years to build a reputation and five minutes to ruin it.',
      'author': 'Warren Buffett',
    },
    {
      'quote': 'The difference between successful people and really successful people is that really successful people say no to almost everything.',
      'author': 'Warren Buffett',
    },
    {
      'quote': 'Risk comes from not knowing what you are doing.',
      'author': 'Warren Buffett',
    },
    {
      'quote': 'Chains of habit are too light to be felt until they are too heavy to be broken.',
      'author': 'Warren Buffett',
    },
    {
      'quote': 'Someone is sitting in the shade today because someone planted a tree a long time ago.',
      'author': 'Warren Buffett',
    },

    // ── Charlie Munger ───────────────────────────────────────────────────
    {
      'quote': 'The big money is not in the buying and selling, but in the waiting.',
      'author': 'Charlie Munger',
    },
    {
      'quote': 'Spend each day trying to be a little wiser than you were when you woke up.',
      'author': 'Charlie Munger',
    },
    {
      'quote': 'Knowing what you don\'t know is more useful than being brilliant.',
      'author': 'Charlie Munger',
    },
    {
      'quote': 'The best thing a human being can do is to help another human being know more.',
      'author': 'Charlie Munger',
    },
    {
      'quote': 'Invert, always invert: Turn a situation or problem upside down. Look at it backward.',
      'author': 'Charlie Munger',
    },
    {
      'quote': 'You don\'t have to be brilliant, only a little bit wiser than the other guys, on average, for a long, long time.',
      'author': 'Charlie Munger',
    },
    {
      'quote': 'It is remarkable how much long-term advantage people like us have gotten by trying to be consistently not stupid, instead of trying to be very intelligent.',
      'author': 'Charlie Munger',
    },

    // ── Steve Jobs ───────────────────────────────────────────────────────
    {
      'quote': 'Your time is limited, so don\'t waste it living someone else\'s life.',
      'author': 'Steve Jobs',
    },
    {
      'quote': 'Stay hungry, stay foolish.',
      'author': 'Steve Jobs',
    },
    {
      'quote': 'Innovation distinguishes between a leader and a follower.',
      'author': 'Steve Jobs',
    },
    {
      'quote': 'The people who are crazy enough to think they can change the world are the ones who do.',
      'author': 'Steve Jobs',
    },
    {
      'quote': 'Design is not just what it looks like and feels like. Design is how it works.',
      'author': 'Steve Jobs',
    },
    {
      'quote': 'Quality is more important than quantity. One home run is much better than two doubles.',
      'author': 'Steve Jobs',
    },
    {
      'quote': 'If you are working on something that you really care about, you don\'t have to be pushed. The vision pulls you.',
      'author': 'Steve Jobs',
    },
    {
      'quote': 'Remembering that you are going to die is the best way I know to avoid the trap of thinking you have something to lose.',
      'author': 'Steve Jobs',
    },

    // ── Alex Hormozi ─────────────────────────────────────────────────────
    {
      'quote': 'You are one skill away from a completely different life.',
      'author': 'Alex Hormozi',
    },
    {
      'quote': 'The longer you delay the ask, the bigger the ask you can make.',
      'author': 'Alex Hormozi',
    },
    {
      'quote': 'Don\'t tell me what you value. Show me your calendar and your bank statement, and I\'ll tell you what you value.',
      'author': 'Alex Hormozi',
    },
    {
      'quote': 'Volume negates luck. The more you do, the less luck matters.',
      'author': 'Alex Hormozi',
    },
    {
      'quote': 'Free is the most expensive thing in the world because it costs you your time.',
      'author': 'Alex Hormozi',
    },
    {
      'quote': 'The goal is not to get rich. The goal is to become the person who can create that level of wealth.',
      'author': 'Alex Hormozi',
    },
    {
      'quote': 'Stop looking for the next opportunity. Double down on the one you have.',
      'author': 'Alex Hormozi',
    },
    {
      'quote': 'The speed of your success is limited only by your willingness to do the boring work.',
      'author': 'Alex Hormozi',
    },

    // ── Andrew Huberman ──────────────────────────────────────────────────
    {
      'quote': 'The best way to build discipline is to do things that are slightly painful on a regular basis.',
      'author': 'Andrew Huberman',
    },
    {
      'quote': 'Morning sunlight is the single most powerful tool for setting your circadian rhythm.',
      'author': 'Andrew Huberman',
    },
    {
      'quote': 'Growth requires a degree of discomfort. The brain changes best when it\'s slightly stressed.',
      'author': 'Andrew Huberman',
    },
    {
      'quote': 'Your ability to focus is directly related to your ability to manage your autonomic nervous system.',
      'author': 'Andrew Huberman',
    },
    {
      'quote': 'Dopamine is not about pleasure. It\'s about motivation and the pursuit of things that are good for you.',
      'author': 'Andrew Huberman',
    },
    {
      'quote': 'Sleep is the foundation of mental health, physical health, and performance.',
      'author': 'Andrew Huberman',
    },
    {
      'quote': 'Consistency over intensity. Small daily actions lead to massive results over time.',
      'author': 'Andrew Huberman',
    },
  ];
}
