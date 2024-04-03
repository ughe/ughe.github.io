---
title: "SCSI, OSI, and Artificial Intelligence"
modified: 2024-04-03
---

## A Question

Here's a story I like to tell, with audience involvement. Sometimes people ask
me about artificial intelligence,[^1] and what I think. In response, I like to ask
them the following question:

[^1]: Specifically referring to generative artificial intelligence, such as ChatGPT which, according to Google Search, was launched on November 30, 2022

> What layer is SCSI in the OSI Model?

In order to answer this question, you need to know two things:
1. What is SCSI?
2. What is the OSI Model?

This is a question that I have been asking a lot of people recently. Naturally,
many of these people have never heard of SCSI or the OSI Model before because
of these terms' esoteric, dated, and domain-specific nature.

The explanation of the two terms that I usually give out loud is something along
the lines of:

* SCSI (or out loud "Skuhzee") is a physical interface for connecting computers
to storage or other peripherals. It looks like a USB plug from the 1980's.[^2]

[^2]: There are likely few reasons to talk about SCSI today. SCSI is antiquated and has been superceded by SATA and PCIe. SCSI stands for Small Computer System Interface. SATA stands for Serial Attached SCSI. PCIe stands for Peripheral Component Interconnect express. [https://en.wikipedia.org/wiki/SCSI](https://en.wikipedia.org/wiki/SCSI)

* The OSI Model (pronounced O.S.I.) has seven layers: (1) physical, (2) data link,
(3) network, (4) transport, (5) session, (6) presentation, (7) application. While
a general framework, the OSI Model might best be explained by applying it to the
internet. For example: (1) copper wire, radio frequency, etc; (2) rules to
communicate over physical layer, (3) internet packets (IP), (4) messages made
up of IP packets (TCP/UDP protocols), (5) session is a sequence of messages, (6) encryption
or compression, (7) website or app data sent over network.
The importance of the model is the general idea, not remembering every layer.[^3]

[^3]: The OSI Model, like SCSI, also became prominent in the 1980s and is also esoteric. Some concepts might be re-used on multiple layers. For example, exponential backoff is applied to both the Ethernet protocol as well as to TCP retransmission. "Open Systems Interconnection" [https://en.wikipedia.org/wiki/OSI_model](https://en.wikipedia.org/wiki/OSI_model)

> What layer is SCSI in the OSI Model?

At first glance, it might appear that this question is beyond reasonable
expectations for someone to correctly answer, if they're unfamiliar with SCSI
and OSI.

However, I haven't heard a wrong answer so far. The challenge of the question
isn't the rote knowledge of the Computer Science terms. The challenge that the
people whom I've spoken with have solved is the ability to reason about new
thoughts. They are able to
make connections about new information (SCSI and the OSI Model) without any
previous knowledge about the relationship between those two distinct concepts.

The punchline, after the listener gets the answer correct, is that all the AI
models (that I have seen so far) get the answer wrong.[^9] This serves as a starting point
to discuss the capabilities of AI. What it can do in practice, what it can do
in theory, and why we shouldn't be surprised that it can make simple logic
errors that appear obvious to humans who have access to the same necessary
information.

[^9]: **Update on 4/3/2024:** after this blog post went to press, I have received a report of ChatGPT getting this question correct as well as incorrect. This suggests there could be a large variance to the answers.

## The Answer

A hypothesis for why ChatGPT and Bard are unable to answer this question is
because there's no data available[^4] that states the correct answer. Both of them
are able to correctly define SCSI and all seven layers of the OSI Model before
they go on to give the wrong answer.

There is no answer given here. By giving an answer, we might defeat the test.
Alan Turing originated the idea of a Turing Test, which posed the question
of if a test could be devised to tell humans and computers apart.[^5] Many websites
today use Captchas,[^6] which are a form of Turing Test.
We will give an MD5 hash of the answer so that it can be revealed in
the future. The hash is:

```
17c69c1ec0963bafd905466d6cc9ae07
```

[^4]: The closest results online on Google Search that I've found are: ["Which OSI layer does iSCSI operate at?"](https://www.datahoards.com/which-osi-layer-does-iscsi-operate-at/), ["OSI model equivalent for storage?"](https://www.reddit.com/r/storage/comments/2a3rpu/osi_model_equivalent_for_storage/), ["Objective 4.1: The OSI Model"](https://en.wikibooks.org/wiki/Network_Plus_Certification/Management/OSI_Model), and ["Storage Networking Protocol Fundamentals: Chapter 2. OSI Reference Model Versus Other Network Models"](https://www.oreilly.com/library/view/storage-networking-protocol/1587051605/ch02.html), which contains the quote: "List the OSI Layers at which the Small Computer System Interface (SCSI) bus, Ethernet, IP... operate." None of these contain the single, definitive answer to this specific question.

[^5]: "The Turing Test." Stanford Encyclopedia of Philosophy. [https://plato.stanford.edu/entries/turing-test/](https://plato.stanford.edu/entries/turing-test/)

[^6]: CAPTCHA stands for "Completely Automated Public Turing test to tell Computers and Humans Apart." [https://en.wikipedia.org/wiki/CAPTCHA](https://en.wikipedia.org/wiki/CAPTCHA)

Knowing what SCSI and the OSI Model are is not enough for AI to pinpoint where
on the model that SCSI belongs. 
This suggests[^9] that on even simple questions,
artificial intelligence can draw incorrect and erroneous conclusions. On the
very same questions, humans are able to create logical connections in the
absence of prior information and to operate in the midst of uncertainty.
Is it possible that every single logical
connection that an artificial intelligence makes is only possible because
someone else had made that connection for it before, somewhere online or in its
private training set?

Imagine if the title of this piece was "SCSI is Layer X on the OSI Model,"
where X is the correct answer. Would ChatGPT and Bard get the correct
answer---after consuming this post? If so, then this would suggest a fragility
of AI that would be prone to the influence of a single result in the absence of
any other data.  The absence of data on a particular topic on the internet is
sometimes called an information void or a data void.[^7]

[^7]: Aslett, Kevin (2024) "Online searches to evaluate misinformation can increase its perceived veracity." Nature. [https://doi.org/10.1038/s41586-023-06883-y](https://doi.org/10.1038/s41586-023-06883-y). See the quote: "These terms can guide users to data voids on search engines, where only one point of an unreliable view is represented." (p. 550). And also see: "Googlewhack," a term for a single-result search. [https://en.wikipedia.org/wiki/Googlewhack](https://en.wikipedia.org/wiki/Googlewhack)

Perhaps the best way to think of generative AI is as search engines, which also
have the challenge of data voids. In *The New Yorker*, Ted Chiang explains generative
AI by using the analogy of lossy compression and raises the idea that the technology
has the capacity to replace "traditional search engines" in the future.[^8]

[^8]: Chiang, Ted. (2023) "ChatGPT Is A Blurry JPEG of the Web" [https://www.newyorker.com/tech/annals-of-technology/chatgpt-is-a-blurry-jpeg-of-the-web](https://www.newyorker.com/tech/annals-of-technology/chatgpt-is-a-blurry-jpeg-of-the-web)

Thank you to everyone who has let me ask them this question as well as for the
thoughtful feedback from TGIF.

## Notes
