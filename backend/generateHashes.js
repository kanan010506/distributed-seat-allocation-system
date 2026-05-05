const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const seedSqlPath = path.join(__dirname, '../database/seed.sql');
const credentialsPath = path.join(__dirname, '../database/credentials.md');

async function main() {
  try {
    let seedSql = fs.readFileSync(seedSqlPath, 'utf8');
    
    // Regex to match the user rows in seed.sql
    // Looks for ('email', 'hash', 'Role'
    const userRowRegex = /\('([^']+)',\s*'(\$2b\$10\$dummy[^']+)',\s*'([^']+)'/g;
    
    const credentials = [];
    credentials.push('ROLE | EMAIL | PLAIN PASSWORD');
    credentials.push('---|---|---');

    let match;
    const replacements = [];

    // Find all matches first
    while ((match = userRowRegex.exec(seedSql)) !== null) {
      const email = match[1];
      const fakeHash = match[2];
      const role = match[3];

      let plainPassword = '';
      if (role === 'Admin') {
        plainPassword = 'Admin@123';
      } else if (role === 'College') {
        plainPassword = 'College@123';
      } else if (role === 'Student') {
        plainPassword = 'Student@123';
      } else {
        plainPassword = 'Password@123'; // fallback
      }

      credentials.push(`${role} | ${email} | ${plainPassword}`);

      // Generate real hash
      // Use bcrypt.hashSync since this is a one-off script and we want to ensure unique salts
      const realHash = bcrypt.hashSync(plainPassword, 10);
      
      replacements.push({
        fakeHash,
        realHash
      });
      
      console.log(`Generated hash for ${email} (${role})`);
    }

    // Replace all fake hashes with real hashes
    // We iterate over the replacements and do a string replace.
    // Since the fake hashes are unique (like dummyhashforstudentaccount001), 
    // a simple replace will work perfectly.
    for (const { fakeHash, realHash } of replacements) {
      seedSql = seedSql.replace(`'${fakeHash}'`, `'${realHash}'`);
    }

    // Write the updated seed.sql
    fs.writeFileSync(seedSqlPath, seedSql, 'utf8');
    console.log(`\nSuccessfully updated ${seedSqlPath}`);

    // Write the credentials.md
    fs.writeFileSync(credentialsPath, credentials.join('\n'), 'utf8');
    console.log(`Successfully generated ${credentialsPath}`);

  } catch (error) {
    console.error('Error processing hashes:', error);
  }
}

main();
