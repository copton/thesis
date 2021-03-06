%% -*- mode: LaTeX -*-

%if style == newcode
%include rae.fmt
%endif

\chapter{Introduction}

Haskell has become a wonderful playground for type system
experimentation. Despite its relative longevity---at roughly 25 years
old~\cite{history-of-haskell}---type theorists still turn to
Haskell as a place to build new type system ideas and see how they work in a
practical setting~\cite{fundeps, chak1, chak2, arrows, syb,
  closed-type-families, generics-with-closed-type-families, safe-coercions-jfp,
  gadts-meet-their-match, helium, pattern-synonyms, typerep}. As a result, Haskell's type system has
grown ever more expressive over the years. As the power of types in Haskell has
increased, Haskellers have started to integrate dependent types into their
programs~\cite{singletons, hasochism, she, clash}, despite the fact that
today's Haskell\footnote{Throughout this dissertation, a reference to
  ``today's Haskell'' refers to the language implemented by the Glasgow
  Haskell Compiler (GHC), version 8.0, released in 2016.} does not internally
support dependent types. Indeed, the desire to program in Haskell but with
support for dependent types influenced the creation of
Cayenne~\cite{cayenne}, Agda~\cite{norell-thesis}, and Idris~\cite{idris};
all are Haskell-like
languages with support for full dependent types.

This dissertation closes the gap, by adding support for dependent types into
Haskell. In this work, I detail both the changes to GHC's internal
language, previously known as System FC~\cite{systemfc} but which I have
renamed \pico/, and the changes to the
surface language necessary to support dependent types. Naturally, I must also
describe the elaboration from the surface language to the internal language,
including type inference through my novel algorithm \bake/.
Along with the textual description contained in this
dissertation, I have also partially implemented these ideas
into GHC directly; indeed, my contributions were one of the key factors
in making the current release of GHC a new major version. It is my expectation
that I will implement the internal language and type inference algorithm described in this
work into GHC in the near future.
Much of my work builds upon the critical work of
\citet{gundry-thesis}; one of my chief contributions is adapting his work
to work with the GHC implementation and further features of Haskell.

\section{Contributions}

I offer the following contributions:
\begin{itemize}
\item \pref{cha:motivation} includes a series of examples of dependently
  typed programming in Haskell. Though a fine line is hard to draw, these
  examples are divided into two categories: programs where rich types give a
  programmer more compile-time checks of her algorithms, and programs where
  rich types allow a programmer to express a more intricate algorithm that
  may not be well-typed under a simpler system. \pref{sec:why-haskell} then
  argues why dependent types in Haskell, in particular, are an interesting
  and worthwhile subject of study.

Although no new results, as such, are presented in \pref{cha:motivation},
these examples are a true contribution of this dissertation.
The two most elaborate examples are:
\begin{itemize}
\item a dependently typed database
access library based on the design of \citet{power-of-pi} but with the
ability to infer a database schema based on how its fields are used, and
\item a translation of Idris's algebraic effects library~\cite{algebraic-effects}
into Dependent Haskell (though runnable today) that allows for an easy-to-use
alternative to monad transformer stacks.
\end{itemize}

\item \pref{cha:dep-haskell} presents Dependent Haskell, the surface language
I have designed in this dissertation. This chapter is written to be useful
to practitioners, being a user manual of sorts of the new features. In
combination with \pref{cha:motivation}, this chapter could serve to educate
Haskellers on how to use the new features.

In some ways, Dependent Haskell is similar to existing dependently typed
languages, drawing no distinction between terms and types and allowing
rich specifications in types. However, it
differs in several key ways from existing approaches to dependent types:
\begin{enumerate}
\item Dependent Haskell has the $\ottkw{Type} : \ottkw{Type}$ axiom, avoiding
the need for an infinite hierarchy of sorts~\cite{russell-universes,luo-ecc} used in other languages.

\item A key issue when writing dependently typed programs is in figuring out
what information is needed at runtime. Dependent Haskell's approach is to
require the programmer to choose whether a quantified variable should be retained
(making a proper $\Pi$-type) or discarded (making a $\forall$-type) during
compilation.

\item In contrast to many dependently typed languages, Dependent Haskell is
agnostic to the issue of termination. There is no termination checker in the
language, and termination is not a prerequisite of type safety. A drawback
of this approach is that some proofs of type equivalence
must be executed at runtime, as discussed in \pref{sec:running-proofs}.

\item As elaborated in \pref{cha:type-inference}, Dependent Haskell retains important
type inference characteristics that exist in previous versions of Haskell (e.g., those
characteristics described by \citet{outsidein}).
In particular, all programs accepted by today's GHC---including those without
type signatures---are also valid in Dependent
Haskell.
\end{enumerate}

\item \pref{cha:pico} presents \pico/ (pronounced ``$\Pi$-co'', never ``peek-o''),
 a new dependently-typed
  $\lambda$-calculus, intended as an internal language suitable as a target
  for compiling Dependent Haskell. \Pico/ allows full dependent types, has
  the $\ottkw{Type} : \ottkw{Type}$ axiom, and yet has no computation in types.
  Instead of allowing type equality to include, say, $\beta\eta$-equivalence
  (as in Coq), type equality in \pico/ is just $\alpha$-equivalence. A richer
  notion of type equivalence is permitted through coercions, which witness the
  equivalence between two types. In this way, \pico/ is a direct descendent
  of System FC~\cite{systemfc,promotion,nokinds,closed-type-families,safe-coercions-jfp} and of the \emph{evidence} language of \citet{gundry-thesis}.

  One of the innovations in \pico/ is separating the function spaces of
  type constants, which are generative and injective, from the ordinary,
  unrestricted function space. Doing this allows \pico/ to support unsaturated
  functions in types as well as to keep function application decomposition
  in its equivalence relation.\footnote{I am referring to the \ottkw{left}
    and \ottkw{right} coercions of System FC here.} Allowing unsaturated
  functions in types is a key step forward \pico/ makes over Gundry's
  \emph{evidence} language~\cite{gundry-thesis}.

  In \pref{app:pico-proofs}, I prove the usual preservation and progress theorems
  for \pico/ as well as a type erasure theorem that relates the operational
  semantics of \pico/ to that of a simple $\lambda$-calculus with datatypes
  and \ottkw{fix}. In this way, I show that all the fancy types really can
  be erased at runtime.

\item \pref{cha:type-inference} contains a technical presentation of the
  Dependent Haskell surface language, providing typing rules and an
  elaboration into \pico/ via a novel algorithm \bake/.
  These typing rules contain an algorithmic
  specification of Dependent Haskell, detailing which programs should
  be accepted and which should be rejected. The type system is bidirectional
  and contains a novel treatment for inferring types around dependent
  pattern matches, among a few other, smaller innovations.
  I prove that the elaborated program is always
  well-typed in \pico/.

\item \pref{cha:implementation} discusses implementation details, including
the current state of the implementation. It focuses
on the released implementation of the system from \citet{nokinds}, which
is part of GHC~8.0. Considerations about implementing full Dependent Haskell
are also included here.

\item \pref{cha:related} puts this work in context by comparing it to
several other dependently typed systems, both theories and implementations.
This chapter also suggests some future work that can build from the base
I lay down here.
\end{itemize}

Though not a new contribution, \pref{cha:prelim} contains a review of features
available in today's Haskell that support dependently typed programming. This
is included as a primer to these features for readers less experienced in
Haskell, and also as a counterpoint to the features discussed as parts of
Dependent Haskell.

\section{Implications beyond Haskell}

This dissertation necessarily focuses quite narrowly on discussing
dependent types within the context of Haskell. What good is this work
to someone uninterested in Haskell? I offer a few answers:
\begin{itemize}
\item In my experience, many people both in the academic community and beyond
believe that a dependently typed language must be total in
order to be type-safe. Though Dependent Haskell is not the first
counterexample to this mistaken notion, the existence of this type-safe,
dependently-typed, non-total language may help to dispel this myth.
\item This is the first work, to my knowledge, to address type inference
with |let|-generalization (of top-level constructs only,
see \pref{sec:let-should-not-be-generalized}) and dependent types. With
the caveat that non-top-level |let| declarations are not generalized,
I claim that the \bake/ algorithm I present in \pref{cha:type-inference}
is conservative over today's Haskell and thus over Hindley-Milner.
See \pref{sec:oi}.
\item Even disregarding |let|-generalization, I am unaware of a careful
study of type inference in the context of dependent types. My
bidirectional type inference algorithm infers whether or not a pattern
match should be treated as a dependent or a traditional match, a feature
that may wish to be ported to other languages.
\item Once Dependent Haskell becomes available, I believe dependent
types will become
popular within the Haskell community, given the strong encouragement
I have received from the community and the popularity of my
\package{singletons} library~\cite{singletons,promoting-type-families}.
Perhaps this popularity will inspire other languages to consider
adding dependent types, amplifying the impact of this work.
\end{itemize}

\begin{center}
\rule{3in}{0.4pt}
\end{center}

As the features in this dissertation continue to become available,
I look forward
to seeing how the Haskell community builds on top of my work and discovers
more and more applications of dependent types.

%%  LocalWords:  newcode rae fmt endif cha FCD Haskellers GHC Agda Idris FC
%%  LocalWords:  GHC's Idris's Coq Gundry's
