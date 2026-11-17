# NUMBER. TITLE

Date: DATE

## Status

STATUS

<!--
Copy to docs/adr/<NNNN>-<kebab-title>.md, fill every section, delete every comment.
Headings stay as written (tools and grep key on them); prose follows the repo's language.
Status is one of: Proposed | Accepted | Rejected | Deprecated
| Superseded by [<N>. <Title>](<NNNN>-<slug>.md)
A record that replaces another adds a line: Supersedes [<N>. <Title>](<NNNN>-<slug>.md)
-->

## Context

<!-- The forces at play: the problem, constraints, what is true today. Facts, not the answer. -->

## Decision

<!-- One decision, in active voice: "Use X for Y." State its scope. -->

## Alternatives considered

<!-- One bullet per rejected option: "<option>: rejected because <reason>." -->

## Consequences

<!-- What becomes easier, what becomes harder, what follow-up work this creates. -->

## Enforced by

<!-- The check that fails when someone breaks this decision, strongest first:
structure > types > lint > tests. Name the rule and the message it prints, e.g.
"`just check` -> depguard `no-db-in-handlers`: 'handlers must call a port, not database/sql'".
Write "Prose only" when nothing enforces it yet; that marks it for a check later. -->
