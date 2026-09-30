// Sample file for the canary fixtures. It is never run.

// TODO: this comment is the target of the synthetic CANARY001 finding.
function greet(name) {
  return `Hello, ${name}`;
}
console.log(greet('canary'));

module.exports = { greet };
