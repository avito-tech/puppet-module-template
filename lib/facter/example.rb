# frozen_string_literal: true

# Facter description here
Facter.add('example') do
  confine do
    # Environment checks, fired before running the main facter code.
    # Example:
    #   Facter::Core::Execution.which('some-binary')
  end
  setcode do
    # Write ruby code here, returning some value
  end
end

