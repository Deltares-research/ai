# AI glossary

This glossary uses practical, tool-agnostic definitions for the terms used throughout this repository. Some terms have slightly different meanings across products and research communities; when that matters, a document should define its intended usage explicitly.

## Agent

An AI-driven system that works toward a goal by interpreting instructions, using available context and tools, taking one or more actions, and evaluating the results. An agent commonly combines a **model**, a **harness**, instructions, tools, and guardrails.

## Context engineering

The deliberate design and management of all information supplied to a model at run time. This can include system prompts, user requests, conversation history, retrieved documents, tool results, and structured state. Its aim is to give the model the right information in a reliable, efficient format.

## Harness

The software layer around a model that makes an AI application or agent operate. A harness may assemble context, call the model, expose tools, manage conversation or task state, enforce permissions, and handle retries, logging, and evaluation.

## Instructions

The rules and guidance that tell an AI system how to behave and complete work. Instructions can specify goals, constraints, preferred workflows, output formats, safety requirements, and repository-specific conventions.

## Large Language Model (LLM)

A machine-learning model trained on large amounts of language data to understand and generate text. LLMs can also support tasks such as summarization, translation, reasoning, code generation, and tool selection.

## Model

A trained machine-learning system that converts input into output. In this repository's AI context, this usually means an LLM, though models can also process images, audio, video, or other data. A model is one component of an agent, not the agent itself.

## Model Context Protocol (MCP)

An open protocol for connecting AI applications to external tools, data sources, and reusable prompts through a consistent client-server interface. An MCP server advertises capabilities that a compatible AI client can discover and use.

## Prompt engineering

The practice of designing and refining prompts so a model produces useful, accurate, and appropriately formatted results. It focuses primarily on the wording and structure of model instructions; **context engineering** has a broader focus on the complete run-time context.

## Retrieval-Augmented Generation (RAG)

A pattern in which an application retrieves relevant information from a knowledge source and supplies it to the model before it generates a response. RAG can ground answers in current or organization-specific material without retraining the model.

## Skill

A reusable, documented package of domain knowledge and operating guidance that helps an AI system perform a particular type of task consistently. In this repository, a skill is typically represented by a `SKILL.md` file and may describe workflows, constraints, reference material, and examples.

## System prompt

High-priority instructions provided by the application or platform that establish an AI system's role, rules, and boundaries. Users generally cannot override system-prompt constraints with later requests.

## Tool calling

The capability for a model to request that the surrounding application run a named operation with structured arguments. The harness validates and executes the request, then returns the tool result to the model so it can continue the task.
